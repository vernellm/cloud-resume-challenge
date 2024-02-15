// API POST CALL

const update = {
    user: "vsubtle"
};

const options = {
    method: "POST",
    body: JSON.stringify(update)
};

fetch('https://vsubtle.com/lambda', options)
.then(data => {
    if (!data.ok) {
        throw Error(data.status)
    }
    return data.json();
})
.then(update => {
    console.log(update);
    const visitorCount = document.querySelector("h3");
    visitorCount.innerHTML = `Visitor Count: ${update.count}`;

})
.catch(e => {
    console.log(e)
})