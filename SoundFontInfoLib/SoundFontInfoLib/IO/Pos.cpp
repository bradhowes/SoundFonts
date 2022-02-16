// Copyright © 2020 Brad Howes. All rights reserved.

#include <iostream>
#include <unistd.h>

#include "IO/ChunkList.hpp"
#include "IO/Format.hpp"

using namespace SF2::IO;

Pos::SeekProcType Pos::SeekProc = &::lseek;
Pos::ReadProcType Pos::ReadProc = &::read;

Chunk
Pos::makeChunk() const
{
  uint32_t buffer[2];
  if (Pos::seek(fd_, off_t(pos_), SEEK_SET) != off_t(pos_)) throw Format::error;
  if (Pos::read(fd_, buffer, sizeof(buffer)) != sizeof(buffer)) throw Format::error;
  return Chunk(Tag(buffer[0]), buffer[1], advance(sizeof(buffer)));
}

ChunkList
Pos::makeChunkList() const
{
  uint32_t buffer[3];
  if (Pos::seek(fd_, off_t(pos_), SEEK_SET) != off_t(pos_)) throw Format::error;
  if (Pos::read(fd_, buffer, sizeof(buffer)) != sizeof(buffer)) throw Format::error;
  return ChunkList(Tag(buffer[0]), buffer[1] - 4, Tag(buffer[2]), advance(sizeof(buffer)));
}
