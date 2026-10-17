#include <docktopus/messages/docktopus_generated.h>

#include <array>
#include <cstdint>
#include <cstdlib>
#include <iostream>
#include <memory>
#include <string>
#include <utility>

namespace {

auto fail(const std::string &message) -> void {
  std::cerr << message << '\n';
  std::exit(EXIT_FAILURE);
}

auto expect(bool condition, const char *message) -> void {
  if (!condition) {
    fail(message);
  }
}

auto makeUuid(std::uint8_t fill) -> docktopus::messages::Uuid {
  std::array<std::uint8_t, 16> bytes{};
  bytes.fill(fill);
  return docktopus::messages::Uuid(bytes);
}

auto makeCode(docktopus::messages::CoreType type, std::uint8_t fill)
    -> std::unique_ptr<docktopus::messages::CodeT> {
  auto code = std::make_unique<docktopus::messages::CodeT>();
  code->type = type;
  code->uuid = std::make_unique<docktopus::messages::Uuid>(makeUuid(fill));
  return code;
}

} // namespace

auto main() -> int {
  using namespace docktopus::messages;

  {
    RegionT region;
    region.code = makeCode(CoreType::Region, 1);
    region.name = "yard";
    region.created_at_ms = 1'700'000'000'000;
    region.last_modified_ms = 1'700'000'100'000;
    region.points = {Coordinates(0.0, 0.0, 0.0), Coordinates(10.0, 4.0, 1.5)};
    region.slices = 5;
    region.slice_width = 2.0;
    region.rows = 2;
    region.columns = 5;

    EnvelopeT envelope;
    envelope.payload.Set(std::move(region));

    ::flatbuffers::FlatBufferBuilder builder;
    FinishEnvelopeBuffer(builder, Envelope::Pack(builder, &envelope));

    ::flatbuffers::Verifier verifier(builder.GetBufferPointer(), builder.GetSize());
    expect(VerifyEnvelopeBuffer(verifier), "region buffer failed verification");
    expect(EnvelopeBufferHasIdentifier(builder.GetBufferPointer()), "region identifier");

    const auto *root = GetEnvelope(builder.GetBufferPointer());
    const auto *read = root->payload_as_Region();
    expect(read != nullptr, "payload is a region");
    expect(read->name()->str() == "yard", "region name");
    expect(read->code()->type() == CoreType::Region, "region code type");
    expect(read->code()->uuid()->bytes()->Get(0) == 1, "region uuid");
    expect(read->code()->uuid()->bytes()->Get(15) == 1, "region uuid tail");
    expect(read->created_at_ms() == 1'700'000'000'000, "region created");
    expect(read->last_modified_ms() == 1'700'000'100'000, "region modified");
    expect(read->points() != nullptr && read->points()->size() == 2, "region points");
    expect(read->points()->Get(0)->x() == 0.0 && read->points()->Get(1)->x() == 10.0, "region x");
    expect(read->points()->Get(1)->y() == 4.0 && read->points()->Get(1)->z() == 1.5, "region yz");
    expect(read->slices() == 5 && read->rows() == 2 && read->columns() == 5, "region grid");
    expect(read->slice_width() == 2.0, "region slice width");
  }

  {
    LocationT location;
    location.code = makeCode(CoreType::Location, 2);
    location.name = "yard:01";
    location.created_at_ms = 1'700'000'200'000;
    location.last_modified_ms = 1'700'000'200'000;
    location.parent = makeCode(CoreType::Region, 1);
    location.row = 0;
    location.column = 1;

    EnvelopeT envelope;
    envelope.payload.Set(std::move(location));

    ::flatbuffers::FlatBufferBuilder builder;
    FinishEnvelopeBuffer(builder, Envelope::Pack(builder, &envelope));

    ::flatbuffers::Verifier verifier(builder.GetBufferPointer(), builder.GetSize());
    expect(VerifyEnvelopeBuffer(verifier), "location buffer failed verification");

    const auto *root = GetEnvelope(builder.GetBufferPointer());
    const auto *read = root->payload_as_Location();
    expect(read != nullptr, "payload is a location");
    expect(read->name()->str() == "yard:01", "location name");
    expect(read->code()->type() == CoreType::Location, "location code type");
    expect(read->parent()->type() == CoreType::Region, "location parent type");
    expect(read->parent()->uuid()->bytes()->Get(0) == 1, "location parent uuid");
    expect(read->code()->uuid()->bytes()->Get(0) == 2, "location uuid");
    expect(read->row() == 0 && read->column() == 1, "location grid");
  }

  return EXIT_SUCCESS;
}
