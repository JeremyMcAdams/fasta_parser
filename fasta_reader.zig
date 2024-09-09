const std = @import("std");
const stdin = std.io.getStdIn().reader();
const cwd = std.fs.cwd();
const print = std.debug.print;
const dna = @import("dna_functions.zig");

pub fn parse_fasta(allocator: std.mem.Allocator, entries: *?[]u64) ?[]u8 {
    var array_list = std.ArrayList(u64).init(allocator);
    defer array_list.deinit();
    var file_buffer: [100]u8 = [_]u8{0} ** 100;
    var fba = std.heap.FixedBufferAllocator.init(&file_buffer);
    const fba_allocator = fba.allocator();
    var file_name: ?[]u8 = null;
    var file: ?std.fs.File = undefined;

    while (file_name == null) {
        print("Please enter a fasta file: ", .{});
        file_name = stdin.readUntilDelimiterOrEofAlloc(fba_allocator, '\n', 100) catch |err| switch (err) {
            error.OutOfMemory => block: {
                print("Error! File name exceeds 100 characters. Consider renaming it and try again\n", .{});
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
    const file_stat  = file.?.stat() catch |err| switch (err) {
        error.AccessDenied => {
            print("Error! Access denied. File is being used by another program or system access to this file has not been permitted. Please contact your administrator.\n", .{});
            return null;
        },
        error.Unexpected => {
            print("Error! An unexpected error has occurred. System did not provide enough information to resolve the error.\n", .{});
            return null;
        },
        error.SystemResources => {
            print("Error! System does not have enough resources to get file size.\n", .{});
            return null;
        },
    };
    const file_size = file_stat.size;
    var file_contents: []u8 = allocator.alloc(u8, file_size) catch |err| switch (err) {
        error.OutOfMemory => {
            alloc_error_message();
            return null;
        }    
    }; 
    var index:usize = 0;

    var buffered_reader = std.io.bufferedReader(file.?.reader());
    const reader = buffered_reader.reader();

    while ( reader.readUntilDelimiterOrEof(file_contents[index..], '\n') catch |err| switch (err) {
        error.NotOpenForReading => {
            print("Error! File is not open for reading. This may be due to another program writing to this file or you do not have permission to read this file\n", .{});
            return null;
        },
        else => {
            print("Unexpected error has occurred. System did not provide details about this error\n", .{});
            return null;
        }       
    }) |line| {
        if (line[0] == '>') {
            array_list.append(index + 1) catch |err| switch (err) {
                error.OutOfMemory => {
                    alloc_error_message();
                    allocator.free(file_contents);
                    return null;
                }
            };
            array_list.append(index + line.len) catch |err| switch (err) {
                error.OutOfMemory => {
                    alloc_error_message();
                    allocator.free(file_contents);
                    return null;
                }
            };
        }
        index += line.len;
    }
    if (allocator.resize(file_contents, index)) {
        file_contents = file_contents[0..index];
    }
    entries.* = array_list.toOwnedSlice() catch |err| switch (err) {error.OutOfMemory => block: {break :block null;}};
    return file_contents;
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

fn alloc_error_message() void {
    print("Error. Not enough free RAM to finish program\nConsider closing some applications and trying again\n", .{});
}

