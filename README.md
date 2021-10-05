# linux-portable-bin
Portable Linux binaries, either fully static or shared with old glibc symbol versioning.
Made for various for red-team and blue-team activities.
Binaries are produced with Docker, using [musl.cc](https://musl.cc/) for static compilation
and [dockcross](https://github.com/dockcross/dockcross) for shared binaries. 
Manual hacks and patches are applied to get desired binaries.

## usage
Change directory to relevant tool and run `run.sh` for available options.
Every `run.sh` has `build` argument to build Docker image and `pack` argument to extract and archive the package.
Example, building and packaging `nmap`:

```
$ cd nmap
$ ./run.sh
$ ./run.sh build x86
$ ./run.sh pack x86
$ ls ./out
ncat-7.80.x86.tar.gz    nmap-7.80.x86.tar.gz    nping-7.80.x86.tar.gz
```

## supported
|                | versions                                                               | features           | x86         | x64         |
| ---------------|------------------------------------------------------------------------|--------------------|-------------|-------------|
| openssl        | [`1.0.2-bad`](https://github.com/drwetter/openssl-1.0.2.bad), `1.1.1l` | `zlib`, `weak-ssl` | static      | static      |
| nmap           | `7.92`, `HEAD` | `bad-ssl`, `weak-ssl`, integrates [`nmap-vulners`](https://github.com/vulnersCom/nmap-vulners), run script  | static | static |
| socat          | `1.7.3.4`                                                              | `ssl`, `weak-ssl`  | static      | static      |
| masscan        | `1.3.2`, `HEAD`                                                        | includes `libpcap` | GLIBC_2.7   | GLIBC_2.7   |
| proxychains-ng | `4.14`, `HEAD`                                                         |                    | GLIBC_2.9   | GLIBC_2.9   |
| oathtool       | `2.6.2`                                                                |                    | static      | static      |

