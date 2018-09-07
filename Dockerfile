## This is a two-stage docker file
# This first stage has opam & a ton of other things
# inside it. The full image is 1.4Gigs! Which is way
# too big to keep around.
FROM ocaml/opam:alpine as base

RUN sudo apk update
RUN sudo apk add m4
RUN sh -c "cd ~/opam-repository && git pull -q"
RUN opam update
# We'll need these two whatever we're building
RUN opam install dune reason

# need these two for building tls, which is needed by cohttp
RUN opam depext conf-gmp.1
RUN opam depext conf-perl.1
RUN opam install tls
# these are the dependencies for our server
RUN opam install lwt cohttp cohttp-lwt-unix

# Now we copy in the source code which is in the current
# directory, and build it with dune
COPY --chown=opam:nogroup . /hello-reason
WORKDIR /hello-reason
RUN sh -c 'eval `opam config env` dune build bin/Server.exe'

## Here's the second, *much* leaner, stage
# The server binary is 8.6mb, and the rest of the operating
# system is only 9mb!
FROM alpine
# `gmp` is an arithmatic library used by the TLS implementation
RUN apk add gmp-dev

# Now copy over our server binary from the "base" image
COPY --from=base /hello-reason/_build/default/bin/Server.exe /server
CMD ["/server"]