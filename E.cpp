#include <iostream>
#include <vector>
#include <algorithm>

using namespace std;

int n, d;
vector<vector<int>> adj;
vector<int> depth_vec;
vector<int> max_depth;
long long total_ans;
int current_root;

// Precompute depths and the maximum depth of each subtree
void dfs_prep(int u, int p, int dep) {
    depth_vec[u] = dep;
    max_depth[u] = 0;
    for (int v : adj[u]) {
        if (v != p) {
            dfs_prep(v, u, dep + 1);
            max_depth[u] = max(max_depth[u], max_depth[v] + 1);
        }
    }
}

// DP function that returns a vector of frequencies of depths
// D[i] represents the number of nodes at distance (D.size() - 1 - i) from u
vector<int> dfs_dp(int u, int p) {
    int v_max = -1;
    for (int v : adj[u]) {
        if (v != p) {
            if (v_max == -1 || max_depth[v] > max_depth[v_max]) {
                v_max = v;
            }
        }
    }

    // Leaf node case
    if (v_max == -1) {
        vector<int> D;
        D.push_back(1); // u itself at distance 0
        return D;
    }

    // Process the heavy child first (reusing the memory space)
    vector<int> D = dfs_dp(v_max, u);

    // Count pairs between u and vertices in the heavy child's subtree
    if (u != current_root) {
        int idx = D.size() + 1 + depth_vec[u] - d;
        if (idx >= 0 && idx < D.size()) {
            total_ans += D[idx];
        }
    }

    // Add u itself to the DP state
    D.push_back((u != current_root) ? 1 : 0);

    // Merge other children into the main DP state
    for (int v : adj[u]) {
        if (v != p && v != v_max) {
            vector<int> D_v = dfs_dp(v, u);
            
            // Count valid pairs between existing subtrees and the new subtree
            for (int res_v = 0; res_v < D_v.size(); ++res_v) {
                int idx_v = D_v.size() - 1 - res_v;
                int idx_D = D.size() + 1 + depth_vec[u] - d + res_v;
                if (idx_D >= 0 && idx_D < D.size()) {
                    total_ans += (long long)D[idx_D] * D_v[idx_v];
                }
            }
            
            // Merge the depth frequencies
            for (int res_v = 0; res_v < D_v.size(); ++res_v) {
                int idx_v = D_v.size() - 1 - res_v;
                D[D.size() - 2 - res_v] += D_v[idx_v];
            }
        }
    }

    return D;
}

void solve() {
    cin >> n >> d;
    adj.assign(n + 1, vector<int>());
    for (int i = 0; i < n - 1; ++i) {
        int u, v;
        cin >> u >> v;
        adj[u].push_back(v);
        adj[v].push_back(u);
    }

    total_ans = 0;
    depth_vec.resize(n + 1);
    max_depth.resize(n + 1);

    // Run the linear DP for every vertex as the root
    for (int r = 1; r <= n; ++r) {
        current_root = r;
        dfs_prep(r, 0, 0);
        dfs_dp(r, 0);
    }

    // Each triple is counted exactly 3 times
    cout << total_ans / 3 << "\n";
}

int main() {
    // Optimize standard I/O operations for performance
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int t;
    if (cin >> t) {
        while (t--) {
            solve();
        }
    }
    return 0;
}