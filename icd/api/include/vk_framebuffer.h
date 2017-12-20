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

#ifndef __VK_FRAMEBUFFER_H__
#define __VK_FRAMEBUFFER_H__

#pragma once

#include "include/khronos/vulkan.h"
#include "include/vk_dispatch.h"
#include "include/vk_object.h"

namespace vk
{

class Image;
class ImageView;

// =====================================================================================================================
// Implementation of a Vulkan framebuffer (VkFramebuffer)
//
// A Framebuffer is a collection of image attachments used for color and depth rendering.  The Framebuffer is used
// in conjunction with a RenderPass and a GraphicsPipeline to describe most of the GPU pipeline state.
//
// Although a RenderPass must be specified as input to create a Framebuffer, that Framebuffer will be compatible with
// other RenderPass objects so long as the attachment count, formats and sample counts are identical between the
// Framebuffer and the other RenderPass.
class Framebuffer : public NonDispatchable<VkFramebuffer, Framebuffer>
{
public:
    struct Attachment
    {
        const ImageView* pView;
        const Image*     pImage;

        // This is largely cached information from one of the above objects so that we don't have to dereference
        // them if possible.
        Pal::SwizzledFormat           viewFormat;         // Format of the view (for color attachments)
        uint32_t                      subresRangeCount;   // Number of attached subres ranges
        Pal::SubresRange              subresRange[MaxRangePerAttachment]; // Attached subres ranges
        Pal::Extent3d                 baseSubresExtent;   // Dimensions of the first subresource in subresRange
        Pal::Range                    zRange;             // Base and num layers for 2D/2D array views of 3D textures
    };

    static VkResult Create(
        Device*                         pDevice,
        const VkFramebufferCreateInfo*  pCreateInfo,
        const VkAllocationCallbacks*    pAllocator,
        VkFramebuffer*                  pFramebuffer);

    VkResult Destroy(
        const Device*                   pDevice,
        const VkAllocationCallbacks*    pAllocator);

    uint32_t GetAttachmentCount() const { return m_attachmentCount; }

    const Framebuffer::Attachment& GetAttachment(uint32_t index) const
        { return m_attachments[index]; }

    static bool IsPartialClear(
        const Pal::Box&   box,
        const Attachment& attachment);

protected:
    Framebuffer(const VkFramebufferCreateInfo& info, Attachment* pAttachments);

    const uint32_t  m_attachmentCount;
    Attachment*     m_attachments;
};

namespace entry
{
VKAPI_ATTR void VKAPI_CALL vkDestroyFramebuffer(
    VkDevice                                    device,
    VkFramebuffer                               framebuffer,
    const VkAllocationCallbacks*                pAllocator);

} // namespace entry

} // namespace vk

#endif /* __VK_FRAMEBUFFER_H__ */
