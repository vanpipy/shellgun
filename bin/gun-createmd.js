'use strict';

/*
 * Create current md
 */
const fs = require('fs');
const path = require('path');

//void
function main () {
    const nowday = new Date();
    const today = `${process.cwd()}/${nowday.getFullYear()}${nowday.getMonth() + 1}${nowday.getDate()}.md`;
    const fd = fs.openSync(today, 'w', (err) => {
        if (err) {
            console.log(`Error: ${err}`);
            return;
        }
    });

    fs.writeSync(fd);
    fs.closeSync(fd);
}

main();
