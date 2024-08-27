const std = @import("std");
const stdin = std.io.getStdIn().reader();
const cwd = std.fs.cwd();
const print = std.debug.print;
const dna = @import("dna_functions.zig");

pub const Fasta = struct {
    id:?[]u8,
    strand:?[]u8,
    length:u64,
};
pub fn parse_fasta(allocator: std.mem.Allocator, entries: *usize) ?[]Fasta {
    var file_buffer: [100]u8 = [_]u8{0} ** 100;
    var fba = std.heap.FixedBufferAllocator.init(&file_buffer);
    const fba_allocator = fba.allocator();
    var file_name: ?[]u8 = null;
    var file: ?std.fs.File = undefined;

    while (file_name == null) {
        print("Please enter a fasta file: ", .{});
        file_name = stdin.readUntilDelimiterOrEofAlloc(fba_allocator, '\n', 100) catch |err| switch (err) {
            error.OutOfMemory => block: {
                print("Error! File name exceeds 100 characters. Condiser renaming it and try again\n", .{});
                while (clear_stdin() == false) {}
                break :block null;
            },
            else => {return null;} 
        };
        if (file_name != null) {
            file = cwd.openFile(@as([]const u8, file_name.?), .{.mode = .read_only}) catch |err| switch (err) {
                error.FileNotFound => block: {
                    print("Error! File not found in current folder\nAdd it to this folder and try again\n", .{});
                    fba_allocator.free(file_name.?);
                    file_name = null;
                    break :block null;
                },
                else => {return null;}
            };
        }
    }
    defer file.?.close();

    var fasta:[]Fasta = allocator.alloc(Fasta, 1) catch |err| switch (err) {
        error.OutOfMemory => {
            alloc_error_message();
            return null;
        },
    }; 
    entries.* += 1;
    fasta[0].id = null;
    var buffered_reader = std.io.bufferedReader(file.?.reader());
    const reader = buffered_reader.reader();
    var file_line:[200:0]u8 = [_:0]u8{0} ** 200;

    while (reader.readUntilDelimiterOrEof(&file_line, '\n') catch |err| switch (err) { else => {return null;}}) |line| {

        //this check is the way it is to decide whether or not a new entry needs to be allocated
        if ((line[0] == '>' or line[0] == ';') and fasta[entries.* - 1].id == null) {
            fasta[entries.* - 1].strand = null;
            fasta[entries.* - 1].length = 0;
            fasta[entries.* - 1].id = allocator.alloc(u8, line.len) catch |err| switch (err) {
                error.OutOfMemory => {
                    alloc_error_message();
                    allocator.free(fasta);
                    return null;
                }
            };
            dna.string_copy(&file_line, fasta[entries.* - 1].id.?, @intCast(line.len));

        }

        //handles fasta file comments
        else if ((line[0] == '>' or line[0] == ';') and fasta[entries.* - 1].id != null and fasta[entries.* - 1].strand == null) {
            continue;
        }
        //determines a new entry needs to be allocated
        else if ((line[0] == '>' or line[0] == ';') and fasta[entries.* - 1].id != null and fasta[entries.* - 1].strand != null) {
            print("finished {s}\n", .{fasta[entries.* - 1].id.?}); //so the user can see the process is progressing
            entries.* += 1;
            fasta = allocator.realloc(fasta, entries.*) catch |err| switch (err) {
                error.OutOfMemory => {
                    alloc_error_message();
                    alloc_error_cleanup(fasta, entries.* - 1, allocator);
                    return null;
                }
            };
            fasta[entries.* - 1].strand = null;
            fasta[entries.* - 1].length = 0;
            fasta[entries.* - 1].id = allocator.alloc(u8, line.len) catch |err| switch (err) {
                error.OutOfMemory => {
                    alloc_error_message();
                    fasta[entries.* - 1].id = null;
                    alloc_error_cleanup(fasta, entries.*, allocator);                   
                    return null;
                }       
            };
            dna.string_copy(&file_line, fasta[entries.* - 1].id.?, @intCast(line.len));
        }
        else {
            fasta[entries.* - 1].length += line.len;
            if (fasta[entries.* - 1].strand == null) {
                fasta[entries.* - 1].strand = allocator.alloc(u8, fasta[entries.* - 1].length) catch |err| switch (err) {
                    error.OutOfMemory => {
                        alloc_error_message();
                        alloc_error_cleanup(fasta, entries.*, allocator);
                        return null;
                    }       
                };
                dna.string_copy(&file_line, fasta[entries.* - 1].strand.?, @intCast(line.len));
            }
            else {
                fasta[entries.* - 1].strand = allocator.realloc(fasta[entries.* - 1].strand.?, fasta[entries.* - 1].length) catch |err| switch (err) {
                    error.OutOfMemory => {
                        alloc_error_message();
                        alloc_error_cleanup(fasta, entries.*, allocator);
                        return null;
                    }
                };
                dna.concat(fasta[entries.* - 1].strand.?[fasta[entries.* - 1].length - line.len..], &file_line); 
            }
        }
    }
    return fasta;
}

fn clear_stdin() bool {
    var buffer:[100]u8 = undefined;
    _ = stdin.readUntilDelimiterOrEof(&buffer, '\n') catch |err| switch (err) {
        error.StreamTooLong => {
            return false;
        },
        else => {return false;},
    };
    return true;
}

pub fn deinit_fasta(self:[]Fasta, size:usize, allocator: std.mem.Allocator) void {
    for (0..size) |i| {
        if (self[i].id) |id| {
            allocator.free(id);
        }
        if (self[i].strand) |strand| {
            allocator.free(strand);
        }
    }
}
fn alloc_error_message() void {
    print("Error. Not enough free RAM to finish program\nConsider closing some applications and trying again\n", .{});
}

fn alloc_error_cleanup(self:[]Fasta, size:usize, allocator:std.mem.Allocator) void {
    deinit_fasta(self, size, allocator);
    allocator.free(self);
}
