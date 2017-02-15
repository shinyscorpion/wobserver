const config     = require('../config');
if(!config.js) return;

const gulp       = require('gulp');
const path       = require('path')


const sourcemaps = require('gulp-sourcemaps');
const browserify = require('browserify');
const babelify   = require('babelify');
const source     = require('vinyl-source-stream');
const buffer     = require('vinyl-buffer');
const uglify     = require('gulp-uglify');

gulp.task('js', () => {
  return browserify({entries: path.join(config.root.src, config.js.src, 'app.js'), extensions: ['.js'], debug: true})
    .transform(babelify, {
      sourceMapsAbsolute: true,
      presets: ['es2015']
    })
    .bundle()
    .pipe(source('app.js'))
    .pipe(buffer())
    .pipe(sourcemaps.init({ loadMaps: true }))
    .pipe(sourcemaps.write('./'))
    .pipe(gulp.dest(path.join(config.root.dest, config.js.dest)));
});

gulp.task('js-prod', () => {
  return browserify({entries: path.join(config.root.src, config.js.src, 'app.js'), extensions: ['.js'], debug: false})
    .transform(babelify, {
      sourceMapsAbsolute: false,
      presets: ['es2015']
    })
    .bundle()
    .pipe(source('app.js'))
    .pipe(buffer())
    .pipe(uglify())
    .pipe(gulp.dest(path.join(config.root.dest, config.js.dest)));
});
