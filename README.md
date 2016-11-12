# MacCraft - tools for the private MacOS Minecraft server

## Features

MacCraft creates standalone Minecraft client and server applications for running
your own private server on your own home network.

### Why

Why would you want standalone applications to run Minecraft clients and servers?
In our house we all want to play together in the same world, but we share
computers. The standalone client applications allow each person to play as
"themselves" regardless of which computer they are using. The standalone server
app allows anyone in the house to double click on the app icon to start the
server. And we can have multiple different server applications depending upon
which world we want to play in.

### How

The applications are actually small shell scripts that start Minecraft when run.
We use [Platypus][] to package up the scripts into a MacOS application complete
with icons.

## Usage

The `bin/maccraft` command is used to generate the client and server
applications. It has some basic help usage to get you started. But read on for a
more details explanation of what is going on.

To create a client application for "John":

```shell
bin/maccraft --client John
```

this generates a `pkg/John Minecraft.app` client application file.

To createa a server application:

```shell
bin/maccraft --server 1.10.2 'Rainbow Unicorn'
```

this generates a `pkg/Rainbow Unicorn.app` server application file.

### Prerequisites

You need to have Minecraft installed and up-to-date on each machine where you
will be playing. Since we are not distributing any of the Minecraft `jar` files,
they must already be present on the machines. The version of Minecraft used to
generate the client apps must be the same on the machien where the client app
will be run.

The server app is a standalone deal. You do not need Minecraft to be installed
on the machine where the server is running. MacCraft will download the server
`jar` file from the [minecraft.net][] download page and package it up into the
server application.

### Players

As you create client applications, the information about each player is stored
in a `config/players.json` file. You can manually edit this file to define new
players and to grant players [operator privileges][] on the server.

Generally you will want to create a client application for each player, and
you'll want to create the clients before creating the server. The reason for
this is the player UUIDs.

#### UUID - Universally Unique Identifier

The Minecraft server is responsible for generating UUIDs for each player. This
works well when the server is authenticating users against the Mojang
authentication service, but we are running a private server disconnected from
the rest of the Internet. We cheat by generating UUIDs for players when the
client application for that player is created.

These UUIDs are stored in the `config/players.json` file and they are used to
populate the `usercache.json` file. This `usercache.json` is used by servers to
map the user to a UUID. So as you add new users to existing servers, you'll want
to keep the `usercache.json` UUIDs in sync with the `config/players.json` UUIDs.

## Development

MacCraft uses:

* Ruby 2
* [Homebrew][]
* [Platypus][]

## License

MIT, see [LICENSE](LICENSE) for details.

[homebrew]: http://brew.sh
[minecraft.net]: https://minecraft.net/en/download/server 
[operator privileges]: http://minecraft.gamepedia.com/Server#Managing_and_maintaining_a_server
[platypus]: https://github.com/sveinbjornt/Platypus
[platypus documentation]: http://sveinbjorn.org/files/manpages/PlatypusDocumentation.html
[platypus manpage]: http://sveinbjorn.org/files/manpages/platypus.man.html

