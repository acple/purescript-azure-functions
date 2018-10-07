"use strict";

exports._logInfo = function (context, a) { context.log.info(a); }

exports._logWarn = function (context, a) { context.log.warn(a); }

exports._logError = function (context, a) { context.log.error(a); }

exports._logVerbose = function (context, a) { context.log.verbose(a); }

exports._setRes = function (context, a) { context.res = a; }
