#lang pyret

import web-server as W

W.serve-servlet(
  fun(req): W.make-response("Set sail for learning island!") end,
  {
    servlet-path: "/",
    static-files: ["./static"],
    port: 9000
  })

