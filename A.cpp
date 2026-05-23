#include <iostream>
#include <vector>
#include <algorithm>

using namespace std;

bool can_partition(const vector<int>& a) {
    int n = a.size();
    // end1 and end2 track the last element of the two non-decreasing subsequences
    int end1 = -1, end2 = -1;
    
    for (int x : a) {
        bool placed = false;
        // Try to place in both, greedily picking the one that keeps the end small
        if (x >= end1 && x >= end2) {
            if (end1 > end2) end1 = x;
            else end2 = x;
            placed = true;
        } else if (x >= end1) {
            end1 = x;
            placed = true;
        } else if (x >= end2) {
            end2 = x;
            placed = true;
        }
        
        if (!placed) return false;
    }
    return true;
}

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    int t; cin >> t;
    while(t--) {
        int n; cin >> n;
        vector<int> a(n);
        for(int i=0; i<n; i++) cin >> a[i];
        if(can_partition(a)) cout << "YES" << endl;
        else cout << "NO" << endl;
    }
    return 0;
}