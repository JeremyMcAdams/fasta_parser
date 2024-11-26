const std = @import("std");
const print = std.debug.print;
const dna = @import("dna_functions.zig");
const fasta = @import("fasta_reader.zig");
var gpa = std.heap.GeneralPurposeAllocator(.{}){};

pub fn main() void {
    defer _ = gpa.deinit();
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();
    const arena_allocator = arena.allocator();

    var entries: ?[]u64 = undefined;    
    const fasta_file = fasta.parse_fasta(arena_allocator, &entries);
    const sites = palindrome(fasta_file.?[entries.?[1]..]);
    defer {
        if (sites) |value| {
            gpa.allocator().free(value);
        }
    }
    
}
fn palindrome(entry:[]const u8) ?[]RestrictionSite {
    var buffer:[20]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const gpa_allocator = gpa.allocator();
    var sites = std.ArrayList(RestrictionSite).init(gpa_allocator);
    defer sites.deinit();
    for (0..entry.len - 3) |i| {
        var size:u8 = if (entry.len - i >= 12) 12 else @intCast(entry.len - i);
        var reverse_strand: ?[]u8 = null;
        reverse_strand = dna.generate_comp_strand(entry[i..i + size], allocator);
        defer allocator.free(reverse_strand.?);
        dna.flip_string(reverse_strand.?);
        var strand_offset:u8 = 0;
        while (size > 3) : ({size -= 1; strand_offset += 1;}) {          
            if (std.mem.eql(u8, entry[i..i + size], reverse_strand.?[strand_offset..]) == true) {
                sites.append(.{.index = @intCast(i), .length = @intCast(reverse_strand.?.len - strand_offset)}) catch |err| switch (err) {
                    error.OutOfMemory => {
                        sites.deinit();
                        return null;
                    }
                };
            }
        }
    }
//    struct_sort(sites.items);
    for (0..sites.items.len) |i| {
        print("{s}: {d} {d}\n", .{entry[sites.items[i].index..sites.items[i].index + sites.items[i].length], sites.items[i].index + 1, sites.items[i].length});
    }
    return sites.toOwnedSlice() catch |err| switch (err) {
        error.OutOfMemory => block: {
            sites.deinit();
            break :block null;
        }
    };
}
const RestrictionSite = struct {
    index:u64,
    length:u8,
};

