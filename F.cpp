#include <iostream>
#include <vector>
#include <algorithm>
#include <cmath>

using namespace std;

const int MAXN = 200005;
bool is_sq[MAXN];

void precompute() {
    for (int i = 0; i * i < MAXN; ++i) {
        is_sq[i * i] = true;
    }
}

void solve() {
    int n, q;
    if (!(cin >> n >> q)) return;
    while (q--) {
        int a, b;
        cin >> a >> b;
        if (a > b) swap(a, b);
        int diff = b - a;
        if (is_sq[diff]) {
            cout << 1 << "\n";
            continue;
        }
        bool found = false;
        for (int i = 1; i * i <= n; ++i) {
            int s = i * i;
            int a1 = a + s;
            if (a1 <= n && is_sq[abs(b - a1)]) {
                found = true;
                break;
            }
            int a2 = a - s;
            if (a2 >= 1 && is_sq[abs(b - a2)]) {
                found = true;
                break;
            }
        }
        if (found) {
            cout << 2 << "\n";
        } else {
            cout << 3 << "\n";
        }
    }
}

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    precompute();
    int t;
    if (cin >> t) {
        while (t--) {
            solve();
        }
    }
    return 0;
}