#lang pyret

import web-server as W
import templates as T

W.serve-servlet(
  fun(req):
    W.make-response(T.render("./static/html/example.html", {
      whalesong-url: "http://localhost:8081"
    }))
  end,
  {
    server-root-path: "./",
    servlet-current-directory: "./",
    servlet-path: "/",
    static-files: ["./static"],
    port: 9000
  })

