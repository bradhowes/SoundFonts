#include <cstddef>
#include <iostream>
#include <memory>
#include <limits>

/**
 Custom allocator for the OldestActiveVoiceCache for the list nodes. We allocate all nodes that we will
 ever need and then keep them when list deallocates them. This is so that we do not incur any memory
 allocations while rendering.
 */
template <typename T>
class ListNodeAllocator {
public:
  using value_type = T;

  /**
   Construct a new allocator that will keep around maxNodeCount nodes.

   @param maxNodeCount max number of list nodes
   */
  ListNodeAllocator(size_t maxNodeCount) noexcept : maxNodeCount_{maxNodeCount} {}

  template <typename U> ListNodeAllocator(const ListNodeAllocator<U>& rhs) noexcept
  : maxNodeCount_{rhs.maxNodeCount_}
  {}

  ListNodeAllocator(const ListNodeAllocator&) = delete;

  ListNodeAllocator(ListNodeAllocator&& other) noexcept
  : maxNodeCount_{other.maxNodeCount_}
  {}

  ~ListNodeAllocator() noexcept
  {
    releaseFreeList();
  }

  ListNodeAllocator& operator =(const ListNodeAllocator&) = delete;

  ListNodeAllocator& operator =(ListNodeAllocator&& other) noexcept {
    releaseFreeList();
    freeList_ = other.freeList;
    other.freeList_ = nullptr;
    return *this;
  }

  value_type* allocate(std::size_t num, const void* = 0)
  {
    assert(num == 1);

    // Allocate our nodes first time asked for one. A better way would be to grab a block of memory and then carve out
    // the individual nodes from it. However, since these allocations happen all at once here, there is a good chance
    // that they are all close together.
    while (maxNodeCount_ > 0) {
      --maxNodeCount_;
      auto node = reinterpret_cast<Node*>(::operator new(sizeof(T)));
      node->next = freeList_;
      freeList_ = node;
    }

    auto ptr = freeList_;
    if (ptr == nullptr) throw std::bad_alloc();
    freeList_ = ptr->next;
    return reinterpret_cast<T*>(ptr);
  }

  void deallocate(value_type* p, std::size_t num)
  {
    assert(num == 1);
    auto ptr = reinterpret_cast<Node*>(p);
    ptr->next = freeList_;
    freeList_ = ptr;
  }

  union Node {
    Node* next;
    typename std::aligned_storage<sizeof(T), alignof(T)>::type storage;
  };

  void releaseFreeList() {
    while (freeList_ != nullptr) {
      auto next = freeList_->next;
      delete freeList_;
      freeList_ = next;
    }
  }

  size_t maxNodeCount_;
  Node* freeList_{nullptr};
};

template <typename T, typename U>
inline bool operator == (const ListNodeAllocator<T>&, const ListNodeAllocator<U>&) {
  return true;
}

template <typename T, typename U>
inline bool operator != (const ListNodeAllocator<T>&, const ListNodeAllocator<U>&) {
  return false;
}
