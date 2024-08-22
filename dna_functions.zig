//inverts the string character order
const print = @import("std").debug.print;
pub fn flip_string(string: []u8) void{
    const halfway = @divFloor(string.len, 2);
    for (0..halfway) |i| {
        string[i] ^= string[string.len - i - 1];
        string[string.len - i - 1] ^= string[i];
        string[i] ^= string[string.len - i - 1];
    }
}
pub fn clear_buffer(buffer:[]u8) void {
    for(0..buffer.len) |index| {
        buffer[index] = 0;
    }
}
//takes the string order of the parent string and inverts the character order in the daughter buffer
pub fn reverse_copy(string: []u8, destination: []u8) void {
    for (string, 0..string.len) |letter, index| {
        destination[string.len - index - 1] = letter;
    }
}

//returns the beginning integer of a slice value in the character array
pub fn substring(string:[]const u8, sub:[]const u8) u64 {
    var sub_start:u32 = 0;
    var i:u32 = 0;
    var j:u32 = 0;
    for (0..string.len) |index|{
        if (string[index] == sub[0]){
            sub_start = @intCast(index);
            i = sub_start;
        
            while (string[i] == sub[j]) : (i += 1) {
                j += 1;
                if (j == sub.len or sub[j] == 0){
                    return sub_start;
                }
            }
            j = 0;
        }
    }
    return @as(u64, string.len);
}

pub fn substring_iterate(string:[]const u8, sub:[]const u8, locs:[]u64) void {
    var sub_start:u32 = 0;
    var i:u32 = 0;
    var j:u32 = 0;
    var sub_loc:u64 = 0;
    for (0..string.len) |index|{
        if (string[index] == sub[0]){
            sub_start = @intCast(index);
            i = sub_start;
        
            while (string[i] == sub[j]) : (i += 1) {
                j += 1;
                if (i + 1 == string.len or string[i + 1] == 0){
                    return;
                }
                if (j == sub.len or sub[j] == 0){
                    print("EOL\n", .{});
                    locs[sub_loc] = sub_start;
                    sub_loc += 1;
                    print("{d}: {s}\n", .{sub_start, string[sub_start..sub_start + 9]});
                    break;
                }
            }
        }
        j = 0;
    }
}

pub fn string_copy(source:[]const u8, destination:[]u8, len: u32) void {
    for (0..len) |index| {
        if (index == source.len) break;
        destination[index] = source[index];
    }
    if (len < destination.len){
        for (len..destination.len) |index|{
            destination[index] = 0;
        }
    }
}

pub fn substring_count(string:[]const u8, sub:[]const u8) u64 {
    var count:u64 = 0;
    var j:u32 = 0;
    var i:u32 = 0;
    for(0..string.len) |index| {
        if (string[index] == 0){break;}
        if (string[index] == sub[0]){
            i = @intCast(index);
            while(string[i] == sub[j]) : (i += 1){
                j += 1;
                if (j == sub.len){
                    count += 1;
                    break;
                }
            }
        }
        j = 0;
    }
    return count;
}

pub fn find_substrings(string:[]const u8, sub:[]const u8, locations:[]u64) void {
    var count:u64 = 0;
    var sub_start:u64 = 0;
    var j:u32 = 0;
    var i:u32 = 0;
    for(0..string.len) |index| {
        if (string[index] == 0){break;}
        if (string[index] == sub[0]){
            i = @intCast(index);
            sub_start = i;
            while(string[i] == sub[j]) : (i += 1){
                j += 1;
                if (j == sub.len){
                    locations[count] = sub_start;
                    if (count == locations.len){
                        return;
                    }
                    count += 1;
                    break;
                }
            }
        }
        j = 0;
    }
}

pub fn generate_comp_strand(string:[]const u8, comp_strand:[]u8) void {
    for (string, 0..string.len) |base, number| {
        switch (base) {
            'A' => {comp_strand[number] = 'T';},
            'T' => {comp_strand[number] = 'A';},
            'G' => {comp_strand[number] = 'C';},
            'C' => {comp_strand[number] = 'G';},
            else => {comp_strand[number] = 0;}
        }
    }
}

pub fn concat(destination: []u8, source: []const u8) void {
    var string_start: usize = end: for (0..destination.len) |index| {
        if (destination[index] == 0 or destination[index] == 0xAA) break :end index;
    } else destination.len;
    var source_start: usize = 0;
    while (string_start != destination.len and source_start != source.len) : ({source_start += 1; string_start += 1;}) {
        destination[string_start] = source[source_start];

    }
}

