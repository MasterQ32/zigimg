const ArrayList = std.ArrayList;
const HeapAllocator = std.heap.HeapAllocator;
const Image = zigimg.Image;
const OctTreeQuantizer = zigimg.OctTreeQuantizer;
const assert = std.debug.assert;
const color = zigimg.color;
const std = @import("std");
const testing = std.testing;
const zigimg = @import("zigimg");
usingnamespace @import("helpers.zig");

test "Build the oct tree with 3 colors" {
    var quantizer = OctTreeQuantizer.init(testing.allocator);
    defer quantizer.deinit();
    const red = color.Color.initRGB(0xFF, 0, 0);
    const green = color.Color.initRGB(0, 0xFF, 0);
    const blue = color.Color.initRGB(0, 0, 0xFF);
    try quantizer.addColor(red);
    try quantizer.addColor(green);
    try quantizer.addColor(blue);
    var paletteStorage: [256]color.Color = undefined;
    var palette = try quantizer.makePalette(256, paletteStorage[0..]);
    expectEq(palette.len, 3);

    expectEq(try quantizer.getPaletteIndex(red), 2);
    expectEq(try quantizer.getPaletteIndex(green), 1);
    expectEq(try quantizer.getPaletteIndex(blue), 0);

    expectEq(palette[0].B, 0xFF);
    expectEq(palette[1].G, 0xFF);
    expectEq(palette[2].R, 0xFF);
}

test "Build a oct tree with 32-bit RGBA bitmap" {
    const MemoryRGBABitmap = @embedFile("fixtures/bmp/windows_rgba_v5.bmp");
    var image = try Image.fromMemory(testing.allocator, MemoryRGBABitmap);
    defer image.deinit();

    var quantizer = OctTreeQuantizer.init(testing.allocator);
    defer quantizer.deinit();

    if (image.pixels) |pixelData| {
        // TODO: Use generic color iterator from Image
        for (pixelData.Argb32) |pixel| {
            try quantizer.addColor(pixel.toColor().premultipliedAlpha());
        }
    }

    var paletteStorage: [256]color.Color = undefined;
    var palette = try quantizer.makePalette(255, paletteStorage[0..]);
    expectEq(palette.len, 255);

    var paletteIndex = try quantizer.getPaletteIndex(color.Color.initRGBA(110, 0, 0, 255));
    expectEq(paletteIndex, 93);
    expectEq(palette[93].R, 110);
    expectEq(palette[93].G, 2);
    expectEq(palette[93].B, 2);
    expectEq(palette[93].A, 255);

    var secondPaletteIndex = try quantizer.getPaletteIndex(color.Color.initRGBA(0, 0, 119, 255));
    expectEq(secondPaletteIndex, 53);
    expectEq(palette[53].R, 0);
    expectEq(palette[53].G, 0);
    expectEq(palette[53].B, 117);
    expectEq(palette[53].A, 255);
}
