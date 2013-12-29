require('fs').writeFile('test.txt', (new Date()).toString());
function f() {
 setTimeout(f, 1000);
}
f();
