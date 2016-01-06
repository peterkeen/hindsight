# Hindsight

Hindsight adds version tracking to your ActiveRecord models. It is a bit different from other versioning gems in that
there is no extra versioning table. All versions remain in same table as the "current" record. This is done in order to
allow tracking changes to associations between different versions. A `latest_versions` scope is provided in order to
return only the latest version of any record in a table.

## Migration
```ruby
Hindsight::Schema.version_table(:names, :of, :tables, :to, :add, :versioning, :to)
```

## Usage
```ruby
class Document < ActiveRecord::Base
  has_hindsight
end
```

### Creating new versions

A new version is created whenever a record is saved. The current record is updated and becomes the new version.
```ruby
document = Document.new
document.version #=> 0

document.save
document.version #=> 1

document.update_attributes(:body => "Once upon a time...", :authors = author_list)
document.version #=> 2
```

A new version can be created from a record, without becoming that new version.
```ruby
document.version #=> 2
new_version = document.new_version(:body => "Once upon a time...")
document.version #=> 2
new_version.version #=> 3
```

The `new_version` method can accept a block argument similar to the block version of `create`.
```ruby
document.new_version |new_version|
  new_version.body = "Once upon a time..."
  new_version.authors = author_list
end
```

Creating a saving or creating a new version from an old version will raise `Hindsight::ReadOnlyVersion` exception.
```ruby
document.new_version #=> a new version is created making document an old version
document.new_version #=> raises Hindsight::ReadOnlyVersion
```

**NOTE:** While association versioning can be maintained using update_attributes, using `collection<<` or `collection=`
will modify the associations on the current version without creating a new version since the versioned record is not
modified by the change. The block form of `new_version` can be used to modify associations by any means as the block
is yielded the new version, so no changes affect the current version.

### Versioning Associations
Changes to associations are tracked whenever possible. As new versions of records are created, their associations are
copied to the new version.

Consider the following examples where `Project.has_many :documents`.

```ruby
# A record is added to an association
project_v1.documents #=> []
project_v2 = project.new_version(:documents => [document_a])
project_v1.documents #=> []
project_v2.documents #=> [document_a]
```

```ruby
# A record is moved from one record's association to another record's
alpha_project.documents #=> [document_a]
beta_project.update_attributes(:documents => [document_a])
beta_project.documents #=> [document_a]
alpha_project.versions[-2].documents #=> [document_a] # The previous version still has an associated document...
alpha_project.versions.last.documents #=> [] # ...but the latest version no longer has a document as it has been moved.
```

**NOTE:** To make associations "version-aware", the original association is replaced with a new one that adds a scope on
the end. The additional scope limits the records returned by the association to just those that are the latest version.
The original association is available as "association_name_versions", e.g. "documents_versions", and will include all
versions of all documents attached to this record.

#### belongs_to
Versioned through the mere fact that the foreign key is part of the current record, so changes are automatically
tracked from one version to the next.

#### has_many
Since the foreign key lies with the associated record, these associations are versioned only if the associated record
is versioned. Saving a new version of the current record will update these associations as necessary, also triggering
the creation of new versions of the associated records as their foreign keys are updated to point at this new version.

Un-versioned has_many associations will save as expected, however, older versions of the current record will
lose any trace of those associated records as they are updated to point at the current record's latest version.

#### has_many :through
Changes to these associations are tracked, regardless of whether the associated model is versioned. This is made
possible by the :through record, which is automatically created when assigning a record to the association. One end of
the :through record points at the new version, and the other end point at the (un-)versioned associated record.

## TODO
- Add support for has_one and has_one :through
- Add support for version-aware associations that already have a condition
- Add support for soft-delete
