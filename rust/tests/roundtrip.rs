use docktopus_messages::messages::{
    finish_envelope_buffer, root_as_envelope, Code, CodeArgs, Coordinates, CoreType, Envelope,
    EnvelopeArgs, Location, LocationArgs, Payload, Region, RegionArgs, Uuid,
};
use flatbuffers::FlatBufferBuilder;

fn uuid_is(id: &Uuid, fill: u8) -> bool {
    let bytes = id.bytes();
    (0..16).all(|index| bytes.get(index) == fill)
}

fn region_buffer() -> Vec<u8> {
    let mut builder = FlatBufferBuilder::new();
    let uuid = Uuid::new(&[1; 16]);
    let code = Code::create(
        &mut builder,
        &CodeArgs {
            type_: CoreType::Region,
            uuid: Some(&uuid),
        },
    );
    let name = builder.create_string("yard");
    let points = builder.create_vector(&[
        Coordinates::new(0.0, 0.0, 0.0),
        Coordinates::new(10.0, 4.0, 1.5),
    ]);
    let region = Region::create(
        &mut builder,
        &RegionArgs {
            code: Some(code),
            name: Some(name),
            created_at_ms: 1_700_000_000_000,
            last_modified_ms: 1_700_000_100_000,
            points: Some(points),
            slices: 5,
            slice_width: 2.0,
            rows: 2,
            columns: 5,
        },
    );
    let envelope = Envelope::create(
        &mut builder,
        &EnvelopeArgs {
            payload_type: Payload::Region,
            payload: Some(region.as_union_value()),
        },
    );
    finish_envelope_buffer(&mut builder, envelope);
    builder.finished_data().to_vec()
}

fn location_buffer() -> Vec<u8> {
    let mut builder = FlatBufferBuilder::new();
    let location_uuid = Uuid::new(&[2; 16]);
    let parent_uuid = Uuid::new(&[1; 16]);
    let code = Code::create(
        &mut builder,
        &CodeArgs {
            type_: CoreType::Location,
            uuid: Some(&location_uuid),
        },
    );
    let parent = Code::create(
        &mut builder,
        &CodeArgs {
            type_: CoreType::Region,
            uuid: Some(&parent_uuid),
        },
    );
    let name = builder.create_string("yard:01");
    let location = Location::create(
        &mut builder,
        &LocationArgs {
            code: Some(code),
            name: Some(name),
            created_at_ms: 1_700_000_200_000,
            last_modified_ms: 1_700_000_200_000,
            parent: Some(parent),
            row: 0,
            column: 1,
        },
    );
    let envelope = Envelope::create(
        &mut builder,
        &EnvelopeArgs {
            payload_type: Payload::Location,
            payload: Some(location.as_union_value()),
        },
    );
    finish_envelope_buffer(&mut builder, envelope);
    builder.finished_data().to_vec()
}

#[test]
fn region_roundtrip() {
    let bytes = region_buffer();
    let envelope = root_as_envelope(&bytes).expect("region envelope");
    let region = envelope.payload_as_region().expect("region payload");

    assert_eq!(region.name(), "yard");
    assert_eq!(region.code().type_(), CoreType::Region);
    assert!(uuid_is(region.code().uuid(), 1));
    assert_eq!(region.created_at_ms(), 1_700_000_000_000);
    assert_eq!(region.last_modified_ms(), 1_700_000_100_000);
    let points = region.points().expect("points");
    assert_eq!(points.len(), 2);
    assert_eq!(points.get(0).x(), 0.0);
    assert_eq!(points.get(1).x(), 10.0);
    assert_eq!(points.get(1).y(), 4.0);
    assert_eq!(points.get(1).z(), 1.5);
    assert_eq!(region.slices(), 5);
    assert_eq!(region.slice_width(), 2.0);
    assert_eq!(region.rows(), 2);
    assert_eq!(region.columns(), 5);
}

#[test]
fn location_roundtrip() {
    let bytes = location_buffer();
    let envelope = root_as_envelope(&bytes).expect("location envelope");
    let location = envelope.payload_as_location().expect("location payload");

    assert_eq!(location.name(), "yard:01");
    assert_eq!(location.code().type_(), CoreType::Location);
    assert!(uuid_is(location.code().uuid(), 2));
    assert_eq!(location.parent().type_(), CoreType::Region);
    assert!(uuid_is(location.parent().uuid(), 1));
    assert_eq!(location.row(), 0);
    assert_eq!(location.column(), 1);
}
