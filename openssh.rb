class Openssh < Formula
  desc "OpenBSD freely-licensed SSH connectivity tools"
  homepage "http://www.openssh.com/"
  url "http://ftp.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-7.3p1.tar.gz"
  mirror "https://www.mirrorservice.org/pub/OpenBSD/OpenSSH/portable/openssh-7.3p1.tar.gz"
  version "7.3p1"
  sha256 "3ffb989a6dcaa69594c3b550d4855a5a2e1718ccdde7f5e36387b424220fbecc"

  bottle do
    sha256 "5f4212b2a550da0aac2c8b9e80a964c721e2dd0cb250ee74974c4bb7ab5ee1c9" => :el_capitan
    sha256 "a1f0baf4d1a263735b067aa33443afc42e347d3608d867015995ba4bd4824440" => :yosemite
    sha256 "3323746bb60262ba38591fac908aa59f504d34a5cc7910023e16350e602010e8" => :mavericks
  end

  # Please don't resubmit the keychain patch option. It will never be accepted.
  # https://github.com/Homebrew/homebrew-dupes/pull/482#issuecomment-118994372
  option "with-libressl", "Build with LibreSSL instead of OpenSSL"
  option "with-pkcs11-ecdsa-patch", "Build with patch that supports ECDSA keys over PKCS#11 in ssh-agent"

  depends_on "openssl" => :recommended
  depends_on "libressl" => :optional
  depends_on "ldns" => :optional
  depends_on "pkg-config" => :build if build.with? "ldns"
  unless OS.mac?
    depends_on "homebrew/dupes/libedit"
    depends_on "homebrew/dupes/krb5"
  end

  if OS.mac?
    # Both these patches are applied by Apple.
    patch do
      url "https://raw.githubusercontent.com/Homebrew/patches/1860b0a74/openssh/patch-sandbox-darwin.c-apple-sandbox-named-external.diff"
      sha256 "d886b98f99fd27e3157b02b5b57f3fb49f43fd33806195970d4567f12be66e71"
    end

    patch do
      url "https://raw.githubusercontent.com/Homebrew/patches/d8b2d8c2/openssh/patch-sshd.c-apple-sandbox-named-external.diff"
      sha256 "3505c58bf1e584c8af92d916fe5f3f1899a6b15cc64a00ddece1dc0874b2f78f"
    end

    # Patch for SSH tunnelling issues caused by launchd changes on Yosemite
    patch do
      url "https://raw.githubusercontent.com/Homebrew/patches/d8b2d8c2/OpenSSH/launchd.patch"
      sha256 "df61404042385f2491dd7389c83c3ae827bf3997b1640252b018f9230eab3db3"
    end
  end

  if build.with? "pkcs11-ecdsa-patch"
    patch do
      url "https://bugzilla.mindrot.org/attachment.cgi?id=2728"
      sha256 "222c0a20ce0bd9fc3330ac3c8ccd9ed945172c0bcb7d7a471a7240324c92b104"
    end
  end

  def install
    ENV.append "CPPFLAGS", "-D__APPLE_SANDBOX_NAMED_EXTERNAL__" if OS.mac?

    args = %W[
      --with-libedit
      --with-kerberos5
      --prefix=#{prefix}
      --sysconfdir=#{etc}/ssh
    ]
    args << "--with-pam" if OS.mac?
    args << "--with-privsep-path=#{var}/lib/sshd" if OS.linux?

    if build.with? "libressl"
      args << "--with-ssl-dir=#{Formula["libressl"].opt_prefix}"
    else
      args << "--with-ssl-dir=#{Formula["openssl"].opt_prefix}"
    end

    args << "--with-ldns" if build.with? "ldns"

    system "./configure", *args
    system "make"
    system "make", "install"

    # This was removed by upstream with very little announcement and has
    # potential to break scripts, so recreate it for now.
    # Debian have done the same thing.
    bin.install_symlink bin/"ssh" => "slogin"
  end
end
