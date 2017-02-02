const config       = require('../config');
if(!config.html) return;

const gulp         = require('gulp');
const path         = require('path')

gulp.task('html', () => {
  gulp.src(path.join(config.root.src, config.html.src, config.html.pattern))
    .pipe(gulp.dest(path.join(config.root.dest, config.html.dest)));
});