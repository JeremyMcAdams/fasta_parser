//inverts the string character order
const std = @import("std");
const print = std.debug.print;
const eql = std.mem.eql;
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

pub fn generate_protein(strand:[]const u8, allocator: std.mem.Allocator) ?[]u8 {
    var protein: ?[]u8 = allocator.alloc(u8, 100) catch |err| switch (err) {
        error.OutOfMemory => {
            return null; 
        }    
    };
    var current_max_size:usize = 100;
    var amino_acid_index:usize = 0;
    var strand_index:usize = 0;
    while (strand_index < strand.len) : (strand_index += 3) {
        const codon = strand[strand_index..strand_index + 3];
    //This does some bit shifting to convert each codon to a unique value. This conversion method makes it DNA-RNA agnostic.
    //Internal << 2 shift kicks off the most significant bit all values hold in common and then >> 3 reduces the bits to the smallest unique sets with the same operations
    //Ex A 0100 0001 C 0100 0011 G 0100 0111 T 0101 0100 U 0101 0101
    //<<2  0000 0100   0000 1100   0001 1100   0101 0000   0101 0100
    //>>3  0000 0000   0000 0001   0000 0011   0000 1010   0000 1010  <- Unique encoding values. Notice how T and U are equal. This is what lets it work for both
        const key = (((codon[0] << 2) >> 3) << 4) + (((codon[1] << 2) >> 3) << 2) + ((codon[2] << 2) >> 3);
        switch (key) {
            52, 53, 55, 62 =>{
                protein.?[amino_acid_index] = 'A';     
            }, //Alanine A
            173, 182 => {
                protein.?[amino_acid_index] = 'C'; 
            },//Cysteine C
            49, 58 => {
                protein.?[amino_acid_index] = 'D'; 
            },//Aspartic acid D
            48, 51 => {
                protein.?[amino_acid_index] = 'E'; 
            },//Glutamic acid E
            201, 210 =>{
                protein.?[amino_acid_index] = 'F';
            }, //Phenylalanine F
            60, 61, 63, 70 =>{
                protein.?[amino_acid_index] = 'G'; 
            }, //Glycine G
            17, 26 => {
                protein.?[amino_acid_index] = 'H'; 
            },//Histidine H
            40, 41, 50 =>{
                protein.?[amino_acid_index] = 'I'; 
            }, //Isoleucine I            
            0, 3 => {
                protein.?[amino_acid_index] = 'K'; 
            },//Lysine K
            56, 57, 59, 66, 200, 203 => {
                protein.?[amino_acid_index] = 'L'; 
            },//Leucine L
            43 => {
                protein.?[amino_acid_index] = 'M'; 
            },//Methionine M
            1, 10 => {
                protein.?[amino_acid_index] = 'N'; 
            },//Asparagine N
            20, 21, 23, 30 => {
                protein.?[amino_acid_index] = 'P'; 
            },//proline P
            16, 19 => {
                protein.?[amino_acid_index] = 'Q'; 
            },//Glutamine Q
            12, 15, 28, 29, 31, 38 => {
                protein.?[amino_acid_index] = 'R'; 
            },//Arginine R
            13, 22, 164, 165, 167, 174 =>{
                protein.?[amino_acid_index] = 'S'; 
            }, //Serine S
            4, 5, 7, 14 => {
                protein.?[amino_acid_index] = 'T'; 
            },//Threonine T
            88, 89, 91, 98 => {
                protein.?[amino_acid_index] = 'V'; 
            },//Valine
            175 => {
                protein.?[amino_acid_index] = 'W'; 
            },//Tryptophan W
            161, 170 => {
                protein.?[amino_acid_index] = 'Y'; 
            },//Tyrosine Y
            else => {
                break; 
            },
        }

        amino_acid_index += 1;
        if (amino_acid_index == current_max_size) {
            current_max_size *= 2;
            protein = allocator.realloc(protein.?, current_max_size) catch |err| switch (err) {
                error.OutOfMemory => {
                    allocator.free(protein.?);
                    return null;
                }    
            };
        }
    }
    if(allocator.resize(protein.?, amino_acid_index)) {
        protein = protein.?[0..amino_acid_index];
    }
    return protein.?;
}
