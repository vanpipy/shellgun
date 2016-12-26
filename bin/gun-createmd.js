'use strict';

/*
 * Create current md
 */
const fs = require('fs');
const path = require('path');

//void
function main () {
    const nowday = new Date();
    const currentPath = process.cwd();
    const today = `${nowday.getFullYear()}${nowday.getMonth() + 1}${nowday.getDate()}`;

    fs.open(`${currentPath}/${today}.md`, 'w', (err, fd) => {
        if (err) {
            console.log(`Error: ${err}`);
            return;
        }

        const buffer = new Buffer(`# ${today}\n`);

        fs.write(fd, buffer, 0, buffer.length, 0, (err, written, buffer) => {
            if (err) {
                console.log(`Error: ${err}`);
                return;
            }
        });

        fs.close(fd);
    });
}

main();
