/*
 *******************************************************************************
 *
 * Copyright (c) 2014-2017 Advanced Micro Devices, Inc. All rights reserved.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 ******************************************************************************/

/**
 ***********************************************************************************************************************
 * @file  vk_alloccb.h
 * @brief External declarations for default memory allocator callbacks
 ***********************************************************************************************************************
 */

#ifndef __VK_ALLOCCB_H__
#define __VK_ALLOCCB_H__

#pragma once

#include "include/khronos/vulkan.h"

#include "palSysMemory.h"

namespace vk
{

namespace allocator
{

extern const VkAllocationCallbacks g_DefaultAllocCallback;

void* PAL_STDCALL PalAllocFuncDelegator(
    void*                                   pClientData,
    size_t                                  size,
    size_t                                  alignment,
    Util::SystemAllocType                   allocType);

void PAL_STDCALL PalFreeFuncDelegator(
    void* pClientData,
    void* pMem);

} // namespace allocator

// =====================================================================================================================
// This is an allocator class that can be used to alloc/free memory for generic PAL classes like hash tables through
// the Vulkan callbacks.  The Vulkan Instance object creates and owns one of these.
struct PalAllocator
{
    PalAllocator(VkAllocationCallbacks* pCallbacks);

    void  Init();
    void* Alloc(const Util::AllocInfo& allocInfo);
    void  Free(const Util::FreeInfo& freeInfo);

private:

#if PAL_MEMTRACK
    // NOTE: Memory leak tracking requires an allocator in order to perform the actual allocations. We can't provide
    //       this platform because that would result in a stack overflow. Instead, we define this simple allocator
    //       structure which contains the necessary methods to allocate and free system memory.
    struct MemTrackerAllocator
    {
        void Free(const Util::FreeInfo& freeInfo);
        void* Alloc(const Util::AllocInfo& allocInfo);

        VkAllocationCallbacks* m_pCallbacks;
    };

    MemTrackerAllocator                   m_memTrackerAlloc;
    Util::MemTracker<MemTrackerAllocator> m_memTracker;
#endif
    VkAllocationCallbacks*                     m_pCallbacks;
};

} // namespace vk

#include "palMemTrackerImpl.h"

#endif /*__VK_ALLOCCB_H__*/
