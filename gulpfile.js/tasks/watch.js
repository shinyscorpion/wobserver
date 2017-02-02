const config = require('../config')
const gulp   = require('gulp')
const path   = require('path')
const watch  = require('gulp-watch')

gulp.task('watch', () => {
  config.watch.forEach(type => {
    if( config[type] ){
      gulp.watch(path.join(config.root.src, config[type].src + config[type].pattern), [type])
    }
  })
});