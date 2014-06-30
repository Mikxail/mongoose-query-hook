queryhook = require '..'
should = require 'should'
mongoose = require 'mongoose'

data = [{name: 'name1', num: 1}, {name: 'name2', num: 2}, {name: 'name3', num: 3}]

db = undefined
UserSchema = undefined
User = undefined

beforeEach (done) ->
	db = mongoose.createConnection('mongodb://localhost/query-hook-test', {})
	UserSchema = new mongoose.Schema
		name: String
		num: Number
	User = db.model 'user', UserSchema
	User.create data, done

afterEach (done) ->
	User.remove().withoutpre(->
		UserSchema = undefined
		User = undefined
		db.close ->
			db = undefined
			done()
	)

describe "Import", ->
	it "mongoose plugin", ->
		queryhook.should.be.a.Function
		UserSchema.plugin queryhook

	it "moongose schema has marker", ->
		UserSchema.plugin queryhook
		User.schema._usePreQuery.should.be.ok

	it "query has withoutpre func", ->
		UserSchema.plugin queryhook
		User.find().withoutpre.should.be.a.Function


describe "Mongoose pre query done", ->
	it "on done", (done) ->
		UserSchema.plugin queryhook,
			preQuery: (op, next, done1) ->
				done1(null, [])
		User.find {}, (err, results) ->
			should(err).not.be.ok
			results.should.be.instanceof(Array).and.have.lengthOf(0)
			done()


describe "Mongoose pre query", ->
	beforeEach (done) ->
		UserSchema.plugin queryhook,
			preQuery: (op, next, done) ->
				@where("name", {$ne: "name1"})
				next()
		done()

	it "on find query", (done) ->
		User.find {}, (err, results) ->
			should(err).not.be.ok
			results.should.be.instanceof(Array).and.have.lengthOf(2)
			results = results.sort (a, b) -> a.num - b.num
			results[0].name.should.equal "name2"
			results[1].name.should.equal "name3"
			done()

	it "on find query with exec", (done) ->
		User.find({}).exec (err, results) ->
			should(err).not.be.ok
			results.should.be.instanceof(Array).and.have.lengthOf(2)
			results = results.sort (a, b) -> a.num - b.num
			results[0].name.should.equal "name2"
			results[1].name.should.equal "name3"
			done()

	it "on find query with append where", (done) ->
		User.find({}).where("num", "3").exec (err, results) ->
			should(err).not.be.ok
			results.should.be.instanceof(Array).and.have.lengthOf(1)
			results[0].name.should.equal "name3"
			done()

	it "on findOne query", (done) ->
		User.findOne {}, (err, results) ->
			should(err).not.be.ok
			results.should.be.a.Object
			results.name.should.equal "name2"
			done()

	it "on findOne query with exec", (done) ->
		User.findOne({}).exec (err, results) ->
			should(err).not.be.ok
			results.should.be.a.Object
			results.name.should.equal "name2"
			done()

	it "on count", (done) ->
		User.count {}, (err, results) ->
			should(err).not.be.ok
			results.should.be.a.Number
			results.should.equal 2
			done()

	it "on count with exec", (done) ->
		User.count({}).exec (err, results) ->
			should(err).not.be.ok
			results.should.be.a.Number
			results.should.equal 2
			done()

	it "on update", (done) ->
		User.update {}, {$set: {num: 99}}, {multi: true}, (err, count, results) ->
			should(err).not.be.ok
			count.should.be.equal 2
			User.find {}, (err, results) ->
				should(err).not.be.ok
				results.should.be.instanceof(Array).and.have.lengthOf(2)
				for a in results
					a.num.should.be.equal 99
				done()

	it "on update with exec", (done) ->
		User.update({}, {$set: {num: 99}}, {multi: true}).exec (err, count, results) ->
			should(err).not.be.ok
			count.should.be.equal 2
			User.find {}, (err, results) ->
				should(err).not.be.ok
				results.should.be.instanceof(Array).and.have.lengthOf(2)
				for a in results
					a.num.should.be.equal 99
				done()

	it "on remove", (done) ->
		User.remove {}, (err, count) ->
			should(err).not.be.ok
			count.should.be.equal 2
			User.find {}, (err, results) ->
				should(err).not.be.ok
				results.should.be.instanceof(Array).and.have.lengthOf(0)
				User.find({}).withoutpre().exec (err, results) ->
					should(err).not.be.ok
					results.should.be.instanceof(Array).and.have.lengthOf(1)
					done()

	it "on remove with exec", (done) ->
		User.remove({}).exec (err, count) ->
			should(err).not.be.ok
			count.should.be.equal 2
			User.find {}, (err, results) ->
				should(err).not.be.ok
				results.should.be.instanceof(Array).and.have.lengthOf(0)
				User.find({}).withoutpre().exec (err, results) ->
					should(err).not.be.ok
					results.should.be.instanceof(Array).and.have.lengthOf(1)
					done()

	it "on findOneAndRemove", (done) ->
		User.findOneAndRemove {}, (err, results) ->
			should(err).not.be.ok
			results.should.be.a.Object
			User.find().withoutpre (err, results) ->
				should(err).not.be.ok
				results.should.be.instanceof(Array).and.have.lengthOf(2)
				results = results.sort (a, b) -> a.num - b.num
				results[0].name.should.equal "name1"
				results[1].name.should.equal "name3"
				done()

	it "on findOneAndRemove with exec", (done) ->
		User.findOneAndRemove({}).exec (err, results) ->
			should(err).not.be.ok
			results.should.be.a.Object
			User.find().withoutpre (err, results) ->
				should(err).not.be.ok
				results.should.be.instanceof(Array).and.have.lengthOf(2)
				results = results.sort (a, b) -> a.num - b.num
				results[0].name.should.equal "name1"
				results[1].name.should.equal "name3"
				done()

	it "on findOneAndUpdate", (done) ->
		User.findOneAndUpdate {}, {$set: {num: 99}}, (err, results) ->
			should(err).not.be.ok
			results.should.be.a.Object
			results.num.should.equal 99
			User.find().withoutpre (err, results) ->
				should(err).not.be.ok
				results.should.be.instanceof(Array).and.have.lengthOf(3)
				results = results.sort (a, b) -> a.num - b.num
				results[0].num.should.equal 1
				results[1].num.should.equal 3
				results[2].num.should.equal 99
				done()

	it "on findOneAndUpdate with exec", (done) ->
		User.findOneAndUpdate({}, {$set: {num: 99}}).exec (err, results) ->
			should(err).not.be.ok
			results.should.be.a.Object
			results.num.should.equal 99
			User.find().withoutpre (err, results) ->
				should(err).not.be.ok
				results.should.be.instanceof(Array).and.have.lengthOf(3)
				results = results.sort (a, b) -> a.num - b.num
				results[0].num.should.equal 1
				results[1].num.should.equal 3
				results[2].num.should.equal 99
				done()

	it "on distinct", (done) ->
		User.distinct 'name', (err, results) ->
			should(err).not.be.ok
			results.should.be.instanceof(Array).and.have.lengthOf(2)
			results.should.containEql('name2')
			results.should.containEql('name3')
			results.should.not.containEql('name1')
			done()

	it "on distinct with exec", (done) ->
		User.distinct('name').exec (err, results) ->
			should(err).not.be.ok
			results.should.be.instanceof(Array).and.have.lengthOf(2)
			results.should.containEql('name2')
			results.should.containEql('name3')
			results.should.not.containEql('name1')
			done()



describe "Mongoose post query", ->
	true