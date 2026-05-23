#include <iostream>
#include <vector>
#include <string>
#include <algorithm>

using namespace std;

void solve() {
    int n;
    if (!(cin >> n)) return;
    string s;
    cin >> s;
    vector<long long> a(n + 1);
    for (int i = 1; i <= n; ++i) {
        cin >> a[i];
    }
    vector<long long> c(n + 1);
    for (int i = 1; i <= n; ++i) {
        cin >> c[i];
    }
    
    // Condition 1: c must be non-decreasing
    bool possible = true;
    for (int i = 2; i <= n; ++i) {
        if (c[i] < c[i-1]) {
            possible = false;
        }
    }
    
    if (!possible) {
        cout << "No\n";
        return;
    }
    
    vector<long long> b(n + 1, 0);
    int start = 0;
    
    // Segment the variables into independent components
    while (start <= n) {
        int end = start;
        while (end + 1 <= n && s[end] == '1') {
            end++;
        }
        
        // Compute relative offsets within this component
        vector<long long> A(end - start + 1, 0);
        for (int i = start + 1; i <= end; ++i) {
            A[i - start] = A[i - 1 - start] + a[i];
        }
        
        long long U = 4e18; // Safe upper bound initializer avoiding overflow
        bool has_forced = false;
        long long forced_val = 0;
        
        // Evaluate bounds and equalities for the anchor b[start]
        for (int i = start; i <= end; ++i) {
            long long cur_A = A[i - start];
            if (i >= 1) {
                U = min(U, c[i] - cur_A);
            }
            
            bool forced = false;
            long long val = 0;
            if (i == 0) {
                forced = true;
                val = 0 - cur_A;
            }
            if (i == 1) {
                forced = true;
                val = c[1] - cur_A;
            }
            if (i >= 2 && c[i] > c[i-1]) {
                forced = true;
                val = c[i] - cur_A;
            }
            
            if (forced) {
                if (!has_forced) {
                    has_forced = true;
                    forced_val = val;
                } else {
                    if (forced_val != val) {
                        possible = false;
                    }
                }
            }
        }
        
        long long b_start = 0;
        if (has_forced) {
            if (forced_val > U) {
                possible = false;
            }
            b_start = forced_val;
        } else {
            b_start = U;
        }
        
        if (!possible) break;
        
        // Propagate values to all variables in the component
        for (int i = start; i <= end; ++i) {
            b[i] = b_start + A[i - start];
        }
        
        start = end + 1;
    }
    
    if (!possible) {
        cout << "No\n";
    } else {
        cout << "Yes\n";
        for (int i = 1; i <= n; ++i) {
            cout << b[i] - b[i-1] << (i == n ? "" : " ");
        }
        cout << "\n";
    }
}

int main() {
    // Fast I/O
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