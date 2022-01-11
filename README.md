# How to Use
add `DB= mysql / postgresql` to your `.env` file

# Features

### Query Scope Filtering
```ruby
model.between_date(column, start_date, end_date)
model.before_or_equal_to_date(date, date)
model.after_or_equal_to_date(column, date)
model.at_time(column, time)
model.mysql_json_contains(column, key, value)
```

### Class Method
```ruby
# initialize using hash, the model is not saved yet
Model.new_from_params(params)

# convert from UTC to server date
Model.mysql_date_builder(column)

# convert from UTC to server time
Model.mysql_time_builder(column)

# same as above but for postgresql
Model.postgresql_date_builder(column)
Model.postgresql_time_builder(column)
```

### Instance Method
```ruby
# update a record using hash parameter
# if set_nil = true, the unspesified column will be automatically be set to nil
model.update_by_params(params, set_nil = true)

# available for one-many relationship
# replace all child of this model with specified value from array
# set model accepts_nested_attributes_for :child,allow_destroy: true
model.replace_child_from_array(new_child = [], column_name: "", child_name: "")
```
