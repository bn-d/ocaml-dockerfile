(*
 * Copyright (c) 2014 Anil Madhavapeddy <anil@recoil.org>
 * Copyright (c) 2014 Docker Inc (for the documentation comments, which
 * have been adapted from https://docs.docker.com/reference/builder)
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 *)

(** Generate [Dockerfile] scripts for use with the Docker container manager *)

type t
(** [t] is a single Dockerfile line *)

val string_of_t : t -> string
(** [string_of_t t] converts a {!t} into a Dockerfile format entry *)

val string_of_t_list : t list -> string
(** [string_of_t_list ts] will convert {!ts} into a string that can be used as a [Dockerfile] *)

val comment : ('a, unit, string, t) format4 -> 'a
(** Adds a comment to the Dockerfile for documentation purposes *)

val from : ?tag:string -> string -> t
(** The [from] instruction sets the base image for subsequent instructions.

    - A valid Dockerfile must have [from] as its first instruction. The image
      can be any valid image.
    - [from] must be the first non-comment instruction in the Dockerfile.
    - [from] can appear multiple times within a single Dockerfile in order to
      create multiple images. Simply make a note of the last image ID output
      by the commit before each new FROM command.

    If no [tag] is supplied, [latest] is assumed. If the used tag does not
    exist, an error will be returned. *)

val maintainer :  ('a, unit, string, t) format4 -> 'a
(** [maintainer] sets the author field of the generated images. *)

val run : ('a, unit, string, t) format4 -> 'a
(** [run fmt] will execute any commands in a new layer on top of the current
  image and commit the results. The resulting committed image will be used
  for the next step in the Dockerfile.  The string result of formatting
  [arg] will be passed as a [/bin/sh -c] invocation. *)

val run_exec : string list -> t
(** [run_exec args] will execute any commands in a new layer on top of the current
  image and commit the results. The resulting committed image will be used
  for the next step in the Dockerfile.  The [args] form makes it possible
  to avoid shell string munging, and to run commands using a base image that
  does not contain [/bin/sh]. *)

val cmd : ('a, unit, string, t) format4 -> 'a
(** [cmd args] provides defaults for an executing container. These defaults
  can include an executable, or they can omit the executable, in which case
  you must specify an {!entrypoint} as well.  The string result of formatting
  [arg] will be passed as a [/bin/sh -c] invocation.

  There can only be one [cmd] in a Dockerfile. If you list more than one 
  then only the last [cmd] will take effect. *)

val cmd_exec : string list -> t
(** [cmd_exec args] provides defaults for an executing container. These defaults
  can include an executable, or they can omit the executable, in which case
  you must specify an {!entrypoint} as well.  The first argument to the [args]
  list must be the full path to the executable. 

  There can only be one [cmd] in a Dockerfile. If you list more than one 
  then only the last [cmd] will take effect. *)

val expose_port : int -> t
(** [expose_port] informs Docker that the container will listen on the specified
  network port at runtime. *)

val expose_ports : int list -> t
(** [expose_ports] informs Docker that the container will listen on the specified
  network ports at runtime. *)

val env : (string * string) list -> t
(** [env] sets the list of environment variables supplied with the
  (<key>, <value>) tuple. This value will be passed to all future {!run}
  instructions. This is functionally equivalent to prefixing a shell
  command with [<key>=<value>]. *)

val add : src:string list -> dst:string -> t
(** [add ~src ~dst] copies new files, directories or remote file URLs
  from [src] and adds them to the filesystem of the container at the
  [dst] path.

  Multiple [src] resource may be specified but if they are files or
  directories then they must be relative to the source directory that
  is being built (the context of the build).

  Each [src] may contain wildcards and matching will be done using
  Go's filepath.Match rules. 

  All new files and directories are created with a UID and GID of 0.
  In the case where [src] is a remote file URL, the destination will
  have permissions of 600. If the remote file being retrieved has an
  HTTP Last-Modified header, the timestamp from that header will be
  used to set the mtime on the destination file. Then, like any other
  file processed during an ADD, mtime will be included in the
  determination of whether or not the file has changed and the cache
  should be updated. *)

val copy : src:string list -> dst:string -> t
(** [copy ~src ~dst] copies new files or directories from [src] and
  adds them to the filesystem of the container at the path [dst]. *)

val user : ('a, unit, string, t) format4 -> 'a
(** [user fmt] sets the user name or UID to use when running the image
  and for any {!run}, {!cmd}, {!entrypoint} commands that follow it in
  the Dockerfile.  *)

val workdir :  ('a, unit, string, t) format4 -> 'a
(** [workdir fmt] sets the working directory for any {!run}, {!cmd}
  and {!entrypoint} instructions that follow it in the Dockerfile.

  It can be used multiple times in the one Dockerfile. If a relative
  path is provided, it will be relative to the path of the previous
  {!workdir} instruction. *)

val volume :  ('a, unit, string, t) format4 -> 'a
(** [volume fmt] will create a mount point with the specified name
  and mark it as holding externally mounted volumes from native host
  or other containers. The value can be a JSON array or a plain string
  with multiple arguments that specify several mount points. *)

val volumes : string list -> t
(** [volumes mounts] will create mount points with the specified names
  in [mounts] and mark them as holding externally mounted volumes
  from native host or other containers. *)

val entrypoint :  ('a, unit, string, t) format4 -> 'a
(** [entrypoint fmt] allows you to configure a container that will
  run as an executable.  The [fmt] string will be executed using
  a [/bin/sh] subshell.

  The shell form prevents any {!cmd} or {!run} command line arguments
  from being used, but has the disadvantage that your {!entrypoint}
  will be started as a subcommand of [/bin/sh -c], which does not pass
  signals. This means that the executable will not be the container's
  PID 1 - and will not receive Unix signals - so your executable will
  not receive a SIGTERM from [docker stop <container>].

  To get around this limitation, use the {!entrypoint_exec} command
  to directly execute an argument list without a subshell.
*)

val entrypoint_exec : string list -> t
(** [entrypoint fmt] allows you to configure a container that will
  run as an executable.  You can use the exec form here to set fairly
  stable default commands and arguments and then use either {!cmd} or
  {!cmd_exec} to set additional defaults that are more likely to be changed
  by the user starting the Docker container. *)

val onbuild : t -> t
(** [onbuild t] adds to the image a trigger instruction [t] to be
  executed at a later time, when the image is used as the base for
  another build. The trigger will be executed in the context of the
  downstream build, as if it had been inserted immediately after the
  {!from} instruction in the downstream Dockerfile.

  Any build instruction can be registered as a trigger.

  This is useful if you are building an image which will be used as a
  base to build other images, for example an application build environment
  or a daemon which may be customized with user-specific configuration. *)
