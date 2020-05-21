class DgraphAt20031 < Formula
    desc "Fast, Distributed Graph DB"
    homepage "https://dgraph.io/"

    version "20.03.1"
    url "https://github.com/dgraph-io/dgraph/releases/download/v20.03.1/dgraph-darwin-amd64.tar.gz"
    sha256 "d7ae075a906e4e3133c64a948fb2ce3ad4edc6fd0c97a63e2a81422e425b5a87"
    head "https://github.com/dgraph-io/dgraph.git"

    bottle :unneeded
    keg_only :versioned_formula
    license "Apache-2.0", "https://github.com/dgraph-io/dgraph/blob/master/licenses/APL.txt"

    def install
      bin.install "dgraph", "dgraph-ratel"
    end

    def caveats
      <<~EOS
        By downloading this binary you agree to the terms of use of the Apache-2.0 license.
        If this is unacceptable you should uninstall.

        Run `dgraph --help` for more details or access https://docs.dgraph.io to read the docs.
      EOS
    end
  
    test do
      system "#{bin}/dgraph version"
    end
  end