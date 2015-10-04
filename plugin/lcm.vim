" Greatest Common Divisor thanks to Euclid:
"   a = qb + r,  0 <= r < b
function! s:gcd(x, y)
    let [x, y] = [a:x, a:y]
    while y != 0
        let [x, y] = [y, x % y]
    endwhile
    return x
endfunction

" Least Common Multiple
function! s:lcm(x, y)
    return (a:x == a:y) ? a:x : (abs(a:x * a:y) / s:gcd(a:x, a:y))
endfunction
