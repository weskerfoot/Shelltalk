#! /usr/bin/env racket
#lang racket

(require racket/unix-socket)
(require json)

;; Resource management functions

(define (bail . args)
  (displayln "/tmp/shelltalk.sock could not be created (may already exist)"
             (current-error-port))
  (exit 1))

; All messages come through this socket
; It is cleaned up after execution finishes
(define
  control-socket
  (with-handlers ([exn:fail? bail])
    (unix-socket-listen "/tmp/shelltalk.sock")))

(define (close-socket in out)
  (close-output-port out)
  (close-input-port in))

(define (rm-socket . args)
  ; Removes the socket
  (parameterize ([current-error-port
                   (open-output-string)])

    (system "rm /tmp/shelltalk.sock")))


;; Message handling functions

(define (write-to entries out)
  (with-handlers ([exn:fail? (const '())])
    (write-json entries out)
    (display "\n" out)))

(define (log pid entries)
  (match (thread-receive)
    [(cons 'read out)
     (write-to entries out)
     (log pid entries)]

    [entry
     (log pid (cons entry entries))]))

(define (logger-send loggers pid message)
  (cond
    [(hash-has-key? loggers pid)
      (thread-send (hash-ref loggers pid) message)]
    [else '()]))

(define (handle-messages loggers)
  (match (thread-receive)
    [(list 'log pid entry)
     (logger-send loggers pid entry)
     (handle-messages loggers)]

    [(cons 'spawn pid)
     ;; XXX this should check if it exists already
     (handle-messages (hash-set loggers
                             pid
                             (thread (lambda () (log pid '[])))))]

    [(cons 'kill pid)
     (kill-thread (hash-ref loggers pid))
     (handle-messages
      (hash-remove loggers pid))]

    [(cons 'list out)
     (displayln (hash-keys loggers))
     (write-to
       (hash-keys loggers) out)
     (handle-messages loggers)]

    [(list 'read pid out)
     ; Reads all the logs for a given pid
     (logger-send loggers pid (cons 'read out))
     (handle-messages loggers)]))

(define message-handler
  (thread (lambda ()
            (handle-messages
             (make-immutable-hash '[])))))

(define (handle-connection in out)
  (define input-string (read-line in 'linefeed))
  (cond
    [(eof-object? input-string)
     (close-socket in out)]
    [else
     (match (string-split input-string)
       [(list "spawn" pid)
        (displayln "got spawn")
        (displayln pid)
        (thread-send message-handler (cons 'spawn pid))
        (handle-connection in out)]

       [(list "read" pid)
        (thread-send message-handler (list 'read pid out))
        (handle-connection in out)]

       [(list "write" pid message)
        (thread-send message-handler (list 'log pid message))
        (handle-connection in out)]

       [(list "close" pid)
        (displayln (format "~a closed" pid))
        (thread-send message-handler (cons 'kill pid))
        (close-socket in out)]

       [(list "list")
        (thread-send message-handler (cons 'list out))]

       [other
        (displayln other)
        (handle-connection in out)])]))

;; Socket handling

(define (accept-logs)
  (let-values
      ([(in out) (unix-socket-accept control-socket)])
    (thread
     ; hands the read capability over for this shell instance
     (lambda ()
       (file-stream-buffer-mode out 'none)
       (handle-connection in out))))
  (accept-logs))

; Start execution
; Use dynamic-wind to ensure socket is always cleaned up
(dynamic-wind
  (const '())
  (lambda ()
    (with-handlers ([exn:break? rm-socket]
                    [exn:fail? rm-socket])
      (accept-logs)))
  rm-socket)
