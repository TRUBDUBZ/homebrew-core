class Kubeprod < Formula
  desc "Installer for the Bitnami Kubernetes Production Runtime (BKPR)"
  homepage "https://kubeprod.io"
  url "https://github.com/bitnami/kube-prod-runtime/archive/v1.6.0.tar.gz"
  sha256 "8422eca01462152aa0d25b081acfc8abdeb4d7b031c6116fcfbfb7487e995e76"
  license "Apache-2.0"

  bottle do
    cellar :any_skip_relocation
    sha256 "202ec0c87aed643fe5532a6146b066f5958233e4143aab4b539504b7645891e1" => :catalina
    sha256 "1b6ba93ae6fd9f13a5d14f7ac8732f77fe28469df4b6762f3e8426c0698bae69" => :mojave
    sha256 "55aebc70fa724478dd1eb45829872dcb960e65e3c00606a4b640c4798675b4ac" => :high_sierra
  end

  depends_on "go" => :build

  def install
    cd "kubeprod" do
      system "go", "build", *std_go_args, "-ldflags", "-X main.version=v#{version}", "-mod=vendor"
    end
  end

  test do
    version_output = shell_output("#{bin}/kubeprod version")
    assert_match "Installer version: v#{version}", version_output

    (testpath/"kube-config").write <<~EOS
      apiVersion: v1
      clusters:
      - cluster:
          certificate-authority-data: test
          server: http://127.0.0.1:8080
        name: test
      contexts:
      - context:
          cluster: test
          user: test
        name: test
      current-context: test
      kind: Config
      preferences: {}
      users:
      - name: test
        user:
          token: test
    EOS

    authz_domain = "castle-black.com"
    project = "white-walkers"
    oauth_client_id = "jon-snow"
    oauth_client_secret = "king-of-the-north"
    contact_email = "jon@castle-black.com"

    ENV["KUBECONFIG"] = testpath/"kube-config"
    system "#{bin}/kubeprod", "install", "gke",
                              "--authz-domain", authz_domain,
                              "--project", project,
                              "--oauth-client-id", oauth_client_id,
                              "--oauth-client-secret", oauth_client_secret,
                              "--email", contact_email,
                              "--only-generate"

    json = File.read("kubeprod-autogen.json")
    assert_match "\"authz_domain\": \"#{authz_domain}\"", json
    assert_match "\"client_id\": \"#{oauth_client_id}\"", json
    assert_match "\"client_secret\": \"#{oauth_client_secret}\"", json
    assert_match "\"contactEmail\": \"#{contact_email}\"", json

    jsonnet = File.read("kubeprod-manifest.jsonnet")
    assert_match "https://releases.kubeprod.io/files/v#{version}/manifests/platforms/gke.jsonnet", jsonnet
  end
end
