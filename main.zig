const std = @import("std");

fn save_array(arr: anytype, h: u64, w: u64) !void {
    const rep = 2;
    const file = try std.fs.cwd().createFile("image.pgm", .{});
    defer file.close();

    var meta_slice: [20]u8 = undefined;
    const meta = try std.fmt.bufPrint(meta_slice[0..], "P5\n{} {}\n255\n", .{ w * rep, h * rep });
    try file.writeAll(meta);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const res = try allocator.alloc(u8, h * w * rep * rep);
    defer allocator.free(res);

    for (0..h) |i| {
        for (0..rep) |ri| {
            for (0..w) |j| {
                for (0..rep) |rj| {
                    if (arr[i][j]) {
                        res[(i * rep + ri) * w * rep + j * rep + rj] = 255;
                    }
                    if (!arr[i][j]) {
                        res[(i * rep + ri) * w * rep + j * rep + rj] = 0;
                    }
                }
            }
        }
    }
    try file.writeAll(res[0..]);
}

fn border_wall(arr: anytype, h: u64, w: u64) void {
    for (0..h) |i| {
        arr[i][0] = true;
        arr[i][w - 1] = true;
    }
    for (0..w) |i| {
        arr[0][i] = true;
        arr[h - 1][i] = true;
    }
}

fn internal_grid(arr: anytype, h: u64, w: u64) void {
    for (0..h) |i| {
        if (i % 2 == 0) {
            for (0..w) |j| {
                arr[i][j] = true;
            }
        }
    }
    for (0..w) |i| {
        if (i % 2 == 0) {
            for (0..h) |j| {
                arr[j][i] = true;
            }
        }
    }
}

fn make_connection_matrix(arr: anytype, h: u64, w: u64) void {
    for (0..h) |i| {
        for (0..w) |j| {
            arr[i][j] = i * w + j;
        }
    }
}

fn is_all_connected(arr: anytype, h: u64, w: u64) bool {
    const base = arr[0][0];
    for (0..h) |i| {
        for (0..w) |j| {
            if (base != arr[i][j]) {
                return false;
            }
        }
    }
    return true;
}

fn update_adj(adj: anytype, old: u64, new: u64, h: u64, w: u64) void {
    for (0..h) |i| {
        for (0..w) |j| {
            if (adj[i][j] == old) {
                adj[i][j] = new;
            }
        }
    }
}

fn connect_up(arr: anytype, adj: anytype, h: u64, w: u64, i: u64, j: u64) bool {
    if (i > 0 and adj[i][j] != adj[i - 1][j]) {
        update_adj(adj, adj[i - 1][j], adj[i][j], h / 2, w / 2);
        arr[i * 2][j * 2 + 1] = false;
        return true;
    }
    return false;
}

fn connect_down(arr: anytype, adj: anytype, h: u64, w: u64, i: u64, j: u64) bool {
    if (i < (h / 2) - 1 and adj[i][j] != adj[i + 1][j]) {
        update_adj(adj, adj[i + 1][j], adj[i][j], h / 2, w / 2);
        arr[i * 2 + 2][j * 2 + 1] = false;
        return true;
    }
    return false;
}

fn connect_left(arr: anytype, adj: anytype, h: u64, w: u64, i: u64, j: u64) bool {
    if (j > 0 and adj[i][j] != adj[i][j - 1]) {
        update_adj(adj, adj[i][j - 1], adj[i][j], h / 2, w / 2);
        arr[i * 2 + 1][j * 2] = false;
        return true;
    }
    return false;
}

fn connect_right(arr: anytype, adj: anytype, h: u64, w: u64, i: u64, j: u64) bool {
    if (j < w / 2 - 1 and adj[i][j] != adj[i][j + 1]) {
        update_adj(adj, adj[i][j + 1], adj[i][j], h / 2, w / 2);
        arr[i * 2 + 1][j * 2 + 2] = false;
        return true;
    }
    return false;
}

fn connect_one(arr: anytype, adj: anytype, h: u64, w: u64) !void {
    var prng = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    const rand = prng.random();

    var all_dir: u8 = 0;
    for (0..(h / 2)) |i| {
        for (0..(w / 2)) |j| {
            all_dir = 0;
            while (all_dir < 15) {
                const if_n = rand.intRangeAtMost(u8, 0, 3);
                if (if_n % 4 == 0) {
                    if (connect_up(arr, adj, h, w, i, j)) break;
                    all_dir += 1;
                }
                if (if_n % 4 == 1) {
                    if (connect_down(arr, adj, h, w, i, j)) break;
                    all_dir += 2;
                }
                if (if_n % 4 == 2) {
                    if (connect_left(arr, adj, h, w, i, j)) break;
                    all_dir += 4;
                }
                if (if_n % 4 == 3) {
                    if (connect_right(arr, adj, h, w, i, j)) break;
                    all_dir += 8;
                }
            }
        }
    }
}

pub fn main() !void {
    const w = 961; // should be odd
    const h = 541; // should be odd

    var pic: [h][w]bool = .{.{false} ** w} ** h;

    border_wall(&pic, h, w);
    internal_grid(&pic, h, w);

    var adj: [h / 2][w / 2]u64 = undefined;
    make_connection_matrix(&adj, h / 2, w / 2);

    var step: u64 = 0;
    while (!is_all_connected(&adj, h / 2, w / 2)) {
        try connect_one(&pic, &adj, h, w);
        step += 1;
        std.debug.print("step: {} \n", .{step});
        if (step > 1000) break;
    }

    try save_array(&pic, h, w);
}
