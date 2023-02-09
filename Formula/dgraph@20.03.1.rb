class DgraphAt20031 < Formula
    desc "Fast, Distributed Graph DB"
    homepage "https://dgraph.io/"

    version "20.03.1"
    url "https://github.com/dgraph-io/dgraph/releases/download/v20.03.1/dgraph-darwin-amd64.tar.gz"
    sha256 "5ce1dbb9830025ef98c540637aad969256cda4d375770360e0f6de7c338addf4"
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