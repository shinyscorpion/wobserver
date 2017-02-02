const config       = require('../config');
if(!config.css) return;

const gulp         = require('gulp');
const autoprefixer = require('gulp-autoprefixer');
const sass         = require('gulp-sass')
const sourcemaps   = require('gulp-sourcemaps');
const path         = require('path')

const sassOptions  = {
  errLogToConsole: true,
  outputStyle: 'compressed', //compressed | expanded
};

gulp.task('css', () => {
  gulp.src(path.join(config.root.src, config.css.src, config.css.pattern))
    .pipe(sourcemaps.init())
    .pipe(sass(sassOptions).on('error', sass.logError))
    .pipe(sourcemaps.write())
    .pipe(autoprefixer())
    .pipe(gulp.dest(path.join(config.root.dest, config.css.dest)));
});