#!/usr/bin/env python3
"""
Parse an XML file containing <tag>, <default>, <group> and <entity> elements.

For every <entity> element:
  - If it has Name + ID + Variant + Subtype -> print:
        + ID.Variant.Subtype: Name
  - If some of ID/Variant/Subtype are missing -> print the same format,
    replacing missing values with "???"
  - If it has ONLY Name (no ID, no Variant, no Subtype):
        * if an entity with the same Name and at least one of
          ID/Variant/Subtype has already been seen -> ignore it silently
        * otherwise -> print an error

Errors look like:
    !! [error message] !!
    [element causing the error]

Usage:
    python parse_entities.py path/to/file.xml
"""
## Vibecoded with Claude

import sys
import xml.etree.ElementTree as ET
import bisect


def print_element(elem):
    """Log/print the raw XML of an element (used for error reporting)."""
    print(ET.tostring(elem, encoding="unicode").strip())


def print_error(message, elem):
    print(f"!! {message} !!")
    print_element(elem)


def format_entry(entity):
    id_ = entity.get("ID", "???")
    variant = entity.get("Variant", "???")
    subtype = entity.get("Subtype", "???")
    name = entity.get("Name", "???")
    print(f"+ {id_}.{variant}.{subtype}: {name}")


IGNORED_TAGS = {"tag", "defaults"}


def collect_entities(elem):
    """
    Recursively collect <entity> elements, but do NOT descend into
    <tag>, <default> or <group> elements (their children are ignored too).
    """
    entities = []
    for child in elem:
        if child.tag in IGNORED_TAGS:
            # Skip this element and everything inside it
            continue
        if child.tag == "entity":
            entities.append(child)
            continue
        
        # Some other container -> keep looking inside it
        entities.extend(collect_entities(child))
    return entities

def key_optional_str(s):
    if s is None:
        return float('-inf')
    return int(s)

def process(root, parsed_names):
    # Names that have been seen WITH at least one of ID/Variant/Subtype
    named_with_info = set()

    entities = collect_entities(root)

    # First pass: record which names have an associated (id/variant/subtype)
    for entity in entities:
        name = entity.get("Name")
        if name in parsed_names:
            continue
        
        has_extra = any(
            entity.get(attr) is not None
            for attr in ("ID", "Variant", "Subtype")
        )
        if name is not None and has_extra:
            named_with_info.add(name)

    # Second pass: sort output
    sorted_entities = []
    for entity in entities:
        name = entity.get("Name")
        if name in parsed_names:
            continue

        has_id = entity.get("ID") is not None
        has_variant = entity.get("Variant") is not None
        has_subtype = entity.get("Subtype") is not None

        if has_id or has_variant or has_subtype:
            # Full or partial info -> print bullet, missing ones as "???"
            bisect.insort(
                sorted_entities,
                entity,
                key=lambda e: (
                    key_optional_str(e.get("ID")),
                    key_optional_str(e.get("Variant")),
                    key_optional_str(e.get("Subtype")),
                )
            )
            continue
        # Only Name is present
        if name not in named_with_info:
            print_error(
                f"Entity '{name}' has no ID/Variant/Subtype and no "
                f"matching entity with such info was found",
                entity,
            )
            continue
        # else element already encountered elsewhere with info => ignore
    
    return sorted_entities
    


def main():
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <xml_file>")
        sys.exit(1)

    xml_path = sys.argv[1]

    try:
        tree = ET.parse(xml_path)
    except ET.ParseError as e:
        print(f"!! Failed to parse XML file: {e} !!")
        sys.exit(1)
    
    parsed_names : set[str] = set()
    try:
        with open("names.easyparse", 'r') as f:
            for name in f.readlines():
                parsed_names.add(name[:-1])     # removing the \n
    except FileNotFoundError:
        ...

    root = tree.getroot()
    res = process(root, parsed_names)
    
    with open("names.easyparse", 'a') as f:
        for entity in res:
            format_entry(entity)
            f.write(entity.get("Name") + "\n")


if __name__ == "__main__":
    main()