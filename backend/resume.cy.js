describe('main page', () => {

  before(() => {
    cy.visit('https://vsubtle.com')
  })

  it('h1 is the correct value', () => {
    cy.get("h1").contains("Vernell Mangum")
  })

  context('POST /lambda', () => {
    it('calls the api is correctly', () => {
      cy.request("POST", "https://ygmx5e1a26.execute-api.us-east-1.amazonaws.com/v5/lambda", {'user': 'vsubtle'}).then((response) => {
        expect(response.status).to.eq(200)
        expect(response.statusText).to.eq("OK")
      })
    })

    it('the response body has the correct properties', () => {
      cy.request("POST", "https://ygmx5e1a26.execute-api.us-east-1.amazonaws.com/v5/lambda", {'user': 'vsubtle'}).then((response) => {
        expect(response.body).to.have.property('message')
        expect(response.body).to.have.property('count')
      })
    })

    it('the response body has the correct property types', () => {
      cy.request("POST", "https://ygmx5e1a26.execute-api.us-east-1.amazonaws.com/v5/lambda", {'user': 'vsubtle'}).then((response) => {
        expect(response.body).property('message').to.be.a("string")
        expect(response.body).property('count').to.be.a('number')
      })
    })

    it('visitor count is initialized', () => {
      cy.request("POST", "https://ygmx5e1a26.execute-api.us-east-1.amazonaws.com/v5/lambda", {'user': 'vsubtle'}).then((response) => {
        expect(response.body).property('count').to.be.greaterThan(1)
      })
    })
  })

})