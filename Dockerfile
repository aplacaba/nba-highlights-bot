FROM clfoundation/sbcl:latest

# Install Quicklisp
RUN curl -o /tmp/quicklisp.lisp https://beta.quicklisp.org/quicklisp.lisp && \
    sbcl --non-interactive \
         --eval '(require :asdf)' \
         --load /tmp/quicklisp.lisp \
         --eval '(quicklisp-quickstart:install :path (merge-pathnames "quicklisp/" (user-homedir-pathname)))' && \
    rm /tmp/quicklisp.lisp

# Load Quicklisp on startup
RUN echo '(let ((ql-setup (merge-pathnames "quicklisp/setup.lisp" (user-homedir-pathname)))) (when (probe-file ql-setup) (load ql-setup)))' >> ~/.sbclrc

# Copy project into Quicklisp local-projects
WORKDIR /root/quicklisp/local-projects/nba-highlights-bot/
COPY nba-highlights-bot.asd .
COPY src/ src/

# Pre-load dependencies and system
RUN sbcl --non-interactive \
         --eval '(ql:quickload :nba-highlights-bot)'

ENTRYPOINT ["sbcl", "--non-interactive", \
            "--eval", "(ql:quickload :nba-highlights-bot)", \
            "--eval", "(nba-highlights-bot:start)"]
