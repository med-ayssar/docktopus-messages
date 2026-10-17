import assert from "node:assert/strict";
import { test } from "node:test";

import * as flatbuffers from "flatbuffers";

import {
  Code,
  Coordinates,
  CoreType,
  Envelope,
  Location,
  Payload,
  Region,
  Uuid,
} from "./docktopus/messages.js";
import { unionToPayload } from "./docktopus/messages/payload.js";

function regionBytes(): Uint8Array {
  const builder = new flatbuffers.Builder(256);
  const id = Array.from({ length: 16 }, () => 1);

  Region.startPointsVector(builder, 2);
  Coordinates.createCoordinates(builder, 10, 4, 1.5);
  Coordinates.createCoordinates(builder, 0, 0, 0);
  const points = builder.endVector();
  const name = builder.createString("yard");

  Code.startCode(builder);
  Code.addType(builder, CoreType.Region);
  Code.addUuid(builder, Uuid.createUuid(builder, id));
  const code = Code.endCode(builder);

  const region = Region.createRegion(
    builder,
    code,
    name,
    1_700_000_000_000n,
    1_700_000_100_000n,
    points,
    5n,
    2,
    2n,
    5n,
  );
  Envelope.finishEnvelopeBuffer(
    builder,
    Envelope.createEnvelope(builder, Payload.Region, region),
  );
  return builder.asUint8Array();
}

function locationBytes(): Uint8Array {
  const builder = new flatbuffers.Builder(256);
  const name = builder.createString("yard:01");

  Code.startCode(builder);
  Code.addType(builder, CoreType.Region);
  Code.addUuid(builder, Uuid.createUuid(builder, Array.from({ length: 16 }, () => 1)));
  const parent = Code.endCode(builder);

  Code.startCode(builder);
  Code.addType(builder, CoreType.Location);
  Code.addUuid(builder, Uuid.createUuid(builder, Array.from({ length: 16 }, () => 2)));
  const code = Code.endCode(builder);

  Location.startLocation(builder);
  Location.addCode(builder, code);
  Location.addName(builder, name);
  Location.addCreatedAtMs(builder, 1_700_000_200_000n);
  Location.addLastModifiedMs(builder, 1_700_000_200_000n);
  Location.addParent(builder, parent);
  Location.addRow(builder, 0n);
  Location.addColumn(builder, 1n);
  const location = Location.endLocation(builder);
  Envelope.finishEnvelopeBuffer(
    builder,
    Envelope.createEnvelope(builder, Payload.Location, location),
  );
  return builder.asUint8Array();
}

test("region roundtrip", () => {
  const buffer = new flatbuffers.ByteBuffer(regionBytes());
  assert.equal(Envelope.bufferHasIdentifier(buffer), true);
  const envelope = Envelope.getRootAsEnvelope(buffer);
  assert.equal(envelope.payloadType(), Payload.Region);

  const region = unionToPayload(envelope.payloadType(), (obj) => envelope.payload(obj));
  assert.ok(region instanceof Region);
  assert.equal(region.name(), "yard");
  assert.equal(region.code()?.type(), CoreType.Region);
  assert.equal(region.code()?.uuid()?.bytes(0), 1);
  assert.equal(region.code()?.uuid()?.bytes(15), 1);
  assert.equal(region.createdAtMs(), 1_700_000_000_000n);
  assert.equal(region.lastModifiedMs(), 1_700_000_100_000n);
  assert.equal(region.pointsLength(), 2);
  assert.equal(region.points(0)?.x(), 0);
  assert.equal(region.points(1)?.x(), 10);
  assert.equal(region.points(1)?.y(), 4);
  assert.equal(region.points(1)?.z(), 1.5);
  assert.equal(region.slices(), 5n);
  assert.equal(region.sliceWidth(), 2);
  assert.equal(region.rows(), 2n);
  assert.equal(region.columns(), 5n);
});

test("location roundtrip", () => {
  const buffer = new flatbuffers.ByteBuffer(locationBytes());
  const envelope = Envelope.getRootAsEnvelope(buffer);
  assert.equal(envelope.payloadType(), Payload.Location);

  const location = unionToPayload(envelope.payloadType(), (obj) => envelope.payload(obj));
  assert.ok(location instanceof Location);
  assert.equal(location.name(), "yard:01");
  assert.equal(location.code()?.type(), CoreType.Location);
  assert.equal(location.code()?.uuid()?.bytes(0), 2);
  assert.equal(location.parent()?.type(), CoreType.Region);
  assert.equal(location.parent()?.uuid()?.bytes(0), 1);
  assert.equal(location.row(), 0n);
  assert.equal(location.column(), 1n);
});
