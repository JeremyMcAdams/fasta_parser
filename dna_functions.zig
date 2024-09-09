const std = @import("std");
const log10 = std.math.log10;
const log = std.math.log;
const e = std.math.e;
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
pub fn rna_to_dna(rna_strand:[]const u8, dna_strand:[]u8) void {
    for (0..rna_strand.len) |i| {
        switch (rna_strand[i]) {
            'A' => dna_strand[i] = 'A',
            'a' => dna_strand[i] = 'a',
            'U' => dna_strand[i] = 'T',
            'u' => dna_strand[i] = 't',
            'G' => dna_strand[i] = 'G',
            'g' => dna_strand[i] = 'g',
            'C' => dna_strand[i] = 'C',
            'c' => dna_strand[i] = 'c',
            else => unreachable,
        }
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
                    locs[sub_loc] = sub_start;
                    sub_loc += 1;
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

pub fn find_substrings(string:[]const u8, sub:[]const u8, allocator: std.mem.Allocator) ?[]u64 {
    var sub_start:u64 = 0;
    var j:u32 = 0;
    var i:u32 = 0;
    var locations:std.ArrayList(u64) = std.ArrayList(u64).init(allocator);
    defer locations.deinit();
    errdefer locations.deinit();
    for(0..string.len) |index| {
        if (string[index] == 0){break;}
        if (string[index] == sub[0]){
            i = @intCast(index);
            sub_start = i;
            while(string[i] == sub[j]) : (i += 1){
                j += 1;
                if (j == sub.len){
                    locations.append(sub_start) catch |err| switch (err) {
                        error.OutOfMemory => {
                            return null;
                        }
                    };
                    break;
                }
                if (i == string.len - 1) { break;}
            }
        }
        j = 0;
    }
    return locations.toOwnedSlice() catch |err| switch (err) {
        error.OutOfMemory => block: {
            break :block  null;
        }
    };
}

pub fn generate_comp_strand(string:[]const u8, allocator: std.mem.Allocator) ?[]u8 {
    var comp_strand = std.ArrayList(u8).init(allocator);
    defer comp_strand.deinit();
    for (string) |base| {
        switch (base) {
            'A' => {comp_strand.append('T') catch |err| switch (err) {error.OutOfMemory => {return null;}};},
            'a' => {comp_strand.append('t') catch |err| switch (err) {error.OutOfMemory => {return null;}};},
            'T' => {comp_strand.append('A') catch |err| switch (err) {error.OutOfMemory => {return null;}};},
            't' => {comp_strand.append('a') catch |err| switch (err) {error.OutOfMemory => {return null;}};},
            'G' => {comp_strand.append('C') catch |err| switch (err) {error.OutOfMemory => {return null;}};},
            'g' => {comp_strand.append('c') catch |err| switch (err) {error.OutOfMemory => {return null;}};},
            'C' => {comp_strand.append('G') catch |err| switch (err) {error.OutOfMemory => {return null;}};},
            'c' => {comp_strand.append('g') catch |err| switch (err) {error.OutOfMemory => {return null;}};},
            else => {return null;}
        }
    }
    return comp_strand.toOwnedSlice() catch |err| switch (err) {error.OutOfMemory => block: { break :block null;}};
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
    var start_translation:bool = false;
    var current_max_size:usize = 100;
    var amino_acid_index:usize = 0;
    var strand_index:usize = 0;
    var stop_found:bool = false;
    while (strand_index < strand.len - 3) : (strand_index += 3) {
        const codon = strand[strand_index..strand_index + 3];
    //This does some bit shifting to convert each codon to a unique value. This conversion method makes it DNA-RNA agnostic.
    //Internal << 3 shift kicks off the most significant bit all values hold in common and then >> 4 reduces the bits to the smallest unique sets with the same operations
    //Ex A 0100 0001 a 0110 0001 C 0100 0011 c 0110 0011 G 0100 0111 g 0110 0111 T 0101 0100 t 0111 0100 U 0101 0101 u 0111 0101 
    //<<3  0000 1000   0000 1000   0001 1000   0001 1000   0011 1000   0011 1000   1010 0000   1010 0000   1010 1000   1010 1000
    //>>4  0000 0000   0000 0000   0000 0001   0000 0001   0000 0011   0000 0011   0000 1010   0000 1010   0000 1010   0000 1010 <- Unique encoding values. Notice how T and U are equal. This is what lets it work for both
        const key = (((codon[0] << 3) >> 4) << 4) + (((codon[1] << 3) >> 4) << 2) + ((codon[2] << 3) >> 4);
            
        if (key == 43) {start_translation = true;} 
        if (start_translation == true) {
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
                    stop_found = true;
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
    }
    if (stop_found == false) {
        allocator.free(protein.?);
        return null;
    }
    if(allocator.resize(protein.?, amino_acid_index) == true) {
        protein = protein.?[0..amino_acid_index];
    }
    return protein.?;
}

pub fn simple_melting_point(strand:[]u8) u8 {
    var melt_point:usize = 0;
    for (strand) |i| {
        switch (i) {
            'A', 'a' => melt_point += 2,
            'T', 't' => melt_point += 2,
            'G', 'g' => melt_point += 4,
            'C', 'c' => melt_point += 4,
            else => unreachable,
        }
    }
}

pub fn nearest_neighbor_melting_point(strand:[]const u8) f64 {
    var heat_enthalpy:f64 = 0;
    var entropy:f64 = 0;
    const zero_K_in_C:f64 = -273.15;
    const A:f64 = -0.0108;
    const gas_constant:f64 = 0.00199;
    const monovalent_cations:f64 = 0.05;
    const primer_concentration:f64 = 0.0000005;
    for (0..strand.len) |i| {
        if (i < 1) continue;
        const neighbor_value = (((strand[i-1] << 3) >> 4) << 2) + ((strand[i] << 3) >> 4);
        switch(neighbor_value) {
            0, 50  => { // AA TT
                heat_enthalpy -= 9.1;
                entropy -= 0.0240;
            },
            10 => { //AT
                heat_enthalpy -= 8.6;
                entropy -= 0.0239;
            },
            40 => { //TA
                heat_enthalpy -= 6;
                entropy -= 0.0169;
            },
            4, 43 => { //CA TG
                heat_enthalpy -= 5.8;
                entropy -= 0.0129;
            },
            22, 1 => { //GT AC
                heat_enthalpy -= 6.5;
                entropy -= 0.0173;
            },
            14, 3 => { //CT AG
                heat_enthalpy -= 7.8;
                entropy -= 0.0208;
            },
            12, 41 => { //GA TC
                heat_enthalpy -= 5.6;
                entropy -= 0.0135;
            },
            7 => { //CG
                heat_enthalpy -= 11.9;
                entropy -= 0.0278;
            },
            13 => { //GC
                heat_enthalpy -= 11.1;
                entropy -= 0.0267;
            },
            15, 5 => {
                heat_enthalpy -= 11;
                entropy -= 0.0266;
            },
            else => unreachable,
        } 
    }
    const Tm = (heat_enthalpy / (A + entropy + gas_constant * log(f64, e, (primer_concentration/4)))) + zero_K_in_C + 16.6 * log10(monovalent_cations);
    return Tm;
}
test "Melt point test" {
    const strand = "AAAAACCCCCGGGGGTTTTT";
    const Tm = nearest_neighbor_melting_point(strand);
    std.debug.print("{d}\n", .{Tm});
    try std.testing.expect(Tm > 65.7 and Tm < 74.7);
}
