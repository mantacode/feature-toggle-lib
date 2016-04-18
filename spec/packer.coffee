describe "lib/packer", ->
  Given -> @subject = requireSubject 'lib/packer'

  describe '.sort', ->
    Then -> expect(@subject.sort(
      foo:
        bar:
          baz: 1
        quux: 0
      blah:
        hello: 'world'
    )).toEqual [
      key: 'blah.hello'
      val: 'world'
    ,
      key: 'foo.bar.baz'
      val: 1
    ,
      key: 'foo.quux'
      val: 0
    ]

  describe '.pack', ->
    context 'less than 5 chars', ->
      Then -> expect(@subject.pack(
        foo:
          bar:
            baz: 1
          quux: 0
        blah:
          hello: 1
      )).toBe 'Fz3'

    context 'more than 5 chars', ->
      Then -> expect(@subject.pack(
        a:
          a:
            a: 1
          b:
            a: 1
          c:
            a: 0
        b:
          a:
            a: 0
          b:
            a: 1
          c:
            a: 0
        c: 1
      )).toBe 'YAz2'

    context 'lower and upper thresholds are @ and _', ->
      Then -> expect(@subject.pack(
        a:
          a: 0
          b: 0
          c: 0
          d: 0
          e: 0
        b:
          a: 1
          b: 1
          c: 1
          d: 1
          e: 1
      )).toBe 'a_z5'

  describe '.unpack', ->
    context 'less than 5 chars', ->
      Then -> expect(@subject.unpack('Fz3',
        foo:
          bar:
            baz: 0
          quux: 0
        blah:
          hello: 0
      )).toEqual
        foo:
          bar:
            baz: 1
          quux: 0
        blah:
          hello: 1
      
    context 'more than 5 chars', ->
      Then -> expect(@subject.unpack('YAz2',
        a:
          a:
            a: 0
          b:
            a: 0
          c:
            a: 0
        b:
          a:
            a: 0
          b:
            a: 0
          c:
            a: 0
        c: 0
      )).toEqual
        a:
          a:
            a: 1
          b:
            a: 1
          c:
            a: 0
        b:
          a:
            a: 0
          b:
            a: 1
          c:
            a: 0
        c: 1

    context 'lower and upper thresholds are @ and _', ->
      Then -> expect(@subject.unpack('a_z5',
        a:
          a: 0
          b: 0
          c: 0
          d: 0
          e: 0
        b:
          a: 0
          b: 0
          c: 0
          d: 0
          e: 0
      )).toEqual
        a:
          a: 0
          b: 0
          c: 0
          d: 0
          e: 0
        b:
          a: 1
          b: 1
          c: 1
          d: 1
          e: 1
