const std = @import("std");
const stdin = std.io.getStdIn().reader();
const cwd = std.fs.cwd();
const print = std.debug.print;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();
const dna = @import("dna_functions.zig");

const Fasta = struct {
    id:?[]u8,
    strand:?[]u8,
    length:u64,
};
pub fn main() !void {
    defer _ = gpa.deinit();
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
            else => {return err;} 
        };
        if (file_name != null) {
            file = cwd.openFile(@as([]const u8, file_name.?), .{.mode = .read_only}) catch |err| switch (err) {
                error.FileNotFound => block: {
                    print("Error! File not found in current folder\nAdd it to this folder and try again\n", .{});
                    fba_allocator.free(file_name.?);
                    file_name = null;
                    break :block null;
                },
                else => {return err;}
            };
        }
    }
    defer file.?.close();

    var fasta_entries: usize = 0;
    var fasta:[]Fasta = allocator.alloc(Fasta, 1) catch |err| switch (err) {
        error.OutOfMemory => {
            alloc_error_message();
            return;
        },
    }; 
    defer allocator.free(fasta);
    fasta_entries += 1;
    fasta[0].id = null;
    var buffered_reader = std.io.bufferedReader(file.?.reader());
    const reader = buffered_reader.reader();
    var file_line:[200:0]u8 = [_:0]u8{0} ** 200;

    while (try reader.readUntilDelimiterOrEof(&file_line, '\n') != null) {
        const len = dna.substring(&file_line, "\n");
        //this check is the way it is to decide whether or not a new entry needs to be allocated
        if ((file_line[0] == '>' or file_line[0] == ';') and fasta[fasta_entries - 1].id == null) {
            fasta[fasta_entries - 1].strand = null;
            fasta[fasta_entries - 1].length = 0;
            fasta[fasta_entries - 1].id = allocator.alloc(u8, len) catch |err| switch (err) {
                error.OutOfMemory => {
                    alloc_error_message();
                    return;
                }
            };
            dna.string_copy(&file_line, fasta[fasta_entries - 1].id.?, @intCast(len));

        }
        //handles fasta file comments
        else if ((file_line[0] == '>' or file_line[0] == ';') and fasta[fasta_entries - 1].id != null and fasta[fasta_entries - 1].strand == null) {
            continue;
        }
        else if ((file_line[0] == '>' or file_line[0] == ';') and fasta[fasta_entries - 1].id != null and fasta[fasta_entries - 1].strand != null) {
            print("finished {s}\n", .{fasta[fasta_entries - 1].id.?});
            fasta_entries += 1;
            fasta = allocator.realloc(fasta, fasta_entries) catch |err| switch (err) {
                error.OutOfMemory => {
                    alloc_error_message();
                    return;
                }
            };
            fasta[fasta_entries - 1].strand = null;
            fasta[fasta_entries - 1].length = 0;
            fasta[fasta_entries - 1].id = allocator.alloc(u8, len) catch |err| switch (err) {
                error.OutOfMemory => {
                    alloc_error_message();
                    return;
                }       
            };
            dna.string_copy(&file_line, fasta[fasta_entries - 1].id.?, @intCast(len));
        }
        else {
            fasta[fasta_entries - 1].length += len;
            if (fasta[fasta_entries - 1].strand == null) {
                fasta[fasta_entries - 1].strand = allocator.alloc(u8, fasta[fasta_entries - 1].length) catch |err| switch (err) {
                    error.OutOfMemory => {
                        alloc_error_message();
                        return;
                    }       
                };
                dna.string_copy(&file_line, fasta[fasta_entries - 1].strand.?, @intCast(len));
            }
            else {
                fasta[fasta_entries - 1].strand = allocator.realloc(fasta[fasta_entries - 1].strand.?, fasta[fasta_entries - 1].length) catch |err| switch (err) {
                    error.OutOfMemory => {
                        alloc_error_message();
                        return;
                    }
                };
                dna.concat(fasta[fasta_entries - 1].strand.?[fasta[fasta_entries - 1].length - len..], &file_line); 
            }
        }
        clear_buffer(&file_line);
    }
    for (0..fasta_entries) |i| {
        print("{s}\n", .{fasta[i].id.?});
        print("{s}\n", .{fasta[i].strand.?});
    }
    deinit_fasta(fasta, fasta_entries);
}

fn clear_buffer(buffer:[]u8) void {
    for (0..buffer.len) |i| {
        if (buffer[i] == 0) {break;}
        buffer[i] = 0;
    }
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

fn deinit_fasta(self:[]Fasta, size:usize) void {
    for (0..size) |i| {
        if (self[i].id) |id| {allocator.free(id);}
        if (self[i].strand) |strand| {allocator.free(strand);}
    }
}
fn alloc_error_message() void {
    print("Error. Not enough free RAM to finish program\nConsider closing some applications and trying again\n", .{});
}


