@tool
class_name ImmutableResource
extends Resource

# ImmutableResource — base class for all 10 Resource subtypes (per ADR-0007).
#
# Godot 4.6 limitation: `_set()` virtual is only invoked for UN-declared properties.
# @export-declared properties bypass `_set()` and go directly through the native
# setter, so runtime writes cannot be intercepted at the language level.
#
# The immutability guarantee is therefore enforced by CONVENTION:
#   - All .tres files are treated as read-only data definitions.
#   - Runtime code MUST go through ResourceRegistry to look up resources.
#   - Any `resource.set(...)` or `resource.prop = val` in runtime code is a
#     code smell; the lint manifest (sync_input_bindings pattern) will flag it.
#
# The override below serves as a SAFETY NET for un-declared property writes
# (e.g., typos in property names) — those still go through `_set()` and will
# be rejected.

func _set(property: StringName, value: Variant) -> bool:
    if Engine.is_editor_hint():
        return false
    push_error(
        "ImmutableResourceError: %s.%s = %s " % [resource_path, property, value] +
        "— undeclared property write rejected. " +
        "Resources are immutable at runtime; if this is a typo, fix the property name."
    )
    return true

