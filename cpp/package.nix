{
  lib,
  stdenv,
  cmake,
  flatbuffers,
  repo,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "docktopus-messages";
  version = "0.1.0";

  src = lib.cleanSourceWith {
    src = repo;
    filter =
      path: type:
      let
        base = baseNameOf path;
        rel = lib.removePrefix (toString repo + "/") (toString path);
        top = lib.head (lib.splitString "/" rel);
      in
      # The derivation builds C++ headers only. Rust and TypeScript stay out of the source.
      !(builtins.elem top [
        "rust"
        "typescript"
        "scripts"
      ])
      && !(builtins.elem base [
        "target"
        "node_modules"
        "dist"
        "build"
        "result"
        "result-debug"
      ])
      && lib.cleanSourceFilter path type;
  };

  nativeBuildInputs = [
    cmake
    flatbuffers
  ];
  propagatedBuildInputs = [ flatbuffers ];
  dontUseCmakeConfigure = true;

  buildPhase = ''
    runHook preBuild
    mkdir -p gen/include/docktopus/messages
    flatc --cpp \
      --scoped-enums \
      --gen-mutable \
      --gen-object-api \
      --gen-compare \
      --gen-name-strings \
      --cpp-std c++17 \
      --require-explicit-ids \
      -o gen/include/docktopus/messages \
      schema/docktopus.fbs
    runHook postBuild
  '';

  doCheck = true;

  checkPhase = ''
    runHook preCheck
    $CXX -std=c++23 -Wall -Wextra -Werror -I gen/include cpp/tests/roundtrip.cpp -o roundtrip
    ./roundtrip
    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p \
      $out/include \
      $out/lib/cmake/docktopus-messages \
      $out/lib/pkgconfig \
      $out/share/docktopus-messages
    cp -r gen/include/. $out/include/
    cp schema/docktopus.fbs $out/share/docktopus-messages/docktopus.fbs
    cp cpp/cmake/docktopus-messages-config.cmake $out/lib/cmake/docktopus-messages/
    cp cpp/cmake/docktopus-messages-config-version.cmake $out/lib/cmake/docktopus-messages/
    substitute cpp/cmake/docktopus-messages.pc.in $out/lib/pkgconfig/docktopus-messages.pc \
      --replace-fail @prefix@ "$out" \
      --replace-fail @version@ "${finalAttrs.version}"
    runHook postInstall
  '';

  doInstallCheck = true;

  installCheckPhase = ''
    runHook preInstallCheck
    mkdir -p smoke
    cp cpp/tests/roundtrip.cpp smoke/roundtrip.cpp
    cat > smoke/CMakeLists.txt <<'EOF'
    cmake_minimum_required(VERSION 3.16)
    project(docktopus-messages-smoke CXX)
    find_package(docktopus-messages REQUIRED)
    add_executable(roundtrip roundtrip.cpp)
    target_link_libraries(roundtrip PRIVATE docktopus::messages)
    target_compile_features(roundtrip PRIVATE cxx_std_23)
    EOF
    cmake -S smoke -B smoke/build \
      -DCMAKE_PREFIX_PATH="$out;${flatbuffers}"
    cmake --build smoke/build
    ./smoke/build/roundtrip
    runHook postInstallCheck
  '';

  meta = {
    description = "FlatBuffers C++ headers for docktopus Region and Location messages.";
    license = lib.licenses.mit;
  };
})
