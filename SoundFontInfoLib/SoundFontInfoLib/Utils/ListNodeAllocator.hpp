#include <cstddef>
#include <iostream>
#include <memory>
#include <limits>

namespace SF2::Utils {

/**
 Custom allocator for the OldestActiveVoiceCache for the list nodes. We allocate all nodes that we will
 ever need and then keep them when list deallocates them. This is so that we do not incur any memory
 allocations when voices change while we are rendering.
 */
template <typename T>
class ListNodeAllocator {
public:
  using value_type = T;

  /**
   Construct a new allocator that will keep around maxNodeCount nodes.

   @param maxNodeCount max number of list nodes
   */
  explicit ListNodeAllocator(size_t maxNodeCount) noexcept : maxNodeCount_{maxNodeCount} {}

  /**
   Template conversion constructor for U->T. Just copy the configuration parameter and move on.
   */
  template <typename U> ListNodeAllocator(const ListNodeAllocator<U>& rhs) noexcept : maxNodeCount_{rhs.maxNodeCount()}
  {}

  /**
   Move constructor. Just copy the configuration parameter.
   */
  ListNodeAllocator(ListNodeAllocator&& other) noexcept
  : maxNodeCount_{other.maxNodeCount_}
  {}

  /**
   Destructor. Release any allocated nodes.
   */
  ~ListNodeAllocator() noexcept
  {
    if (memoryBlock_ != nullptr) ::free(memoryBlock_);
    memoryBlock_ = nullptr;
  }

  ListNodeAllocator(const ListNodeAllocator&) = delete;
  ListNodeAllocator& operator =(const ListNodeAllocator&) = delete;
  ListNodeAllocator& operator =(ListNodeAllocator&& other) noexcept = delete;

  union Node {
    Node* next;
    typename std::aligned_storage<sizeof(T), alignof(T)>::type storage;
  };

  /**
   Allocate a new node.

   @param num the number of items to allocate. Asserts if not 1.
   */
  value_type* allocate(std::size_t num, const void* = 0)
  {
    assert(num == 1);

    // Allocate our nodes first time asked for one. A better way would be to grab a block of memory and then carve out
    // the individual nodes from it. However, since these allocations happen all at once here, there is a good chance
    // that they are all close together.
    if (memoryBlock_ == nullptr) {
      size_t elementSize = sizeof(Node);
      size_t totalSize = elementSize * maxNodeCount_;
      memoryBlock_ = ::malloc(totalSize);
      if (memoryBlock_ ==  nullptr) throw std::bad_alloc();
      void* limit = reinterpret_cast<char*>(memoryBlock_) + totalSize;
      Node* ptr = reinterpret_cast<Node*>(memoryBlock_);
      for (size_t index = 0; index < maxNodeCount_; ++index) {
        assert(ptr < limit);
        ptr->next = freeList_;
        freeList_ = ptr;
        ++ptr;
      }
    }

    auto ptr = freeList_;
    if (ptr == nullptr) throw std::bad_alloc();
    freeList_ = ptr->next;
    return reinterpret_cast<T*>(ptr);
  }

  /**
   Deallocate a node.

   @param p pointer to node to deallocate.
   @param num number of items to be deallocated. Must be 1.
   */
  void deallocate(value_type* p, std::size_t num)
  {
    assert(num == 1);
    auto ptr = reinterpret_cast<Node*>(p);
    ptr->next = freeList_;
    freeList_ = ptr;
  }

  size_t maxNodeCount() const { return maxNodeCount_; }

private:
  size_t maxNodeCount_;
  Node* freeList_{nullptr};
  void* memoryBlock_{nullptr};
};

template <typename T, typename U>
inline bool operator == (const ListNodeAllocator<T>&, const ListNodeAllocator<U>&) {
  return true;
}

template <typename T, typename U>
inline bool operator != (const ListNodeAllocator<T>&, const ListNodeAllocator<U>&) {
  return false;
}

}
