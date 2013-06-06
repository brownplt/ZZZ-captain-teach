#lang pyret

import web-server as W
import templates as T

W.serve-servlet(
  fun(req):
    W.make-response(T.render("./tests/run.html", {
      whalesong-url: "http://localhost:8081"
    }))
  end,
  {
    server-root-path: "./",
    servlet-current-directory: "./",
    servlet-path: "/",
    static-files: ["./static", "./tests"],
    port: 10000
  })

