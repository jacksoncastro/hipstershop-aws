import http from 'k6/http';
import { check } from 'k6';

export let options = {
    rps: 50,
    vus: 100,
    duration: '30s'
};

const host = 'http://frontend.default.svc.cluster.local';
const currencies = ['EUR', 'USD', 'JPY', 'CAD'];
const quantities = [1, 2, 3, 4, 5, 10];
const products = [
    '0PUK6V6EV0',
    '1YMWWN1N4O',
    '2ZYFJ3GM2N',
    '66VCHSJNUP',
    '6E92ZMYYFZ',
    '9SIQT8TOJO',
    'L9ECAV7KIM',
    'LS4PSXUNUM',
    'OLJCESPC7Z'
];

const success = response => response.status === 200;

const headers = {
    headers: {
        'Content-Type': 'application/x-www-form-urlencoded'
    }
};

export default function (data) {

    request(index, 1);
    request(setCurrency, 1);
    request(browseProduct, 5);
    request(addToCart, 1);
    request(viewCart, 1);
    request(checkout, 1);

}

function random(array) {
    return array[Math.floor(Math.random() * array.length)];
}

function request(requestFunction, weight) {
    for (let i=0; i <= weight; i++) {
        requestFunction();
    }
}

function index() {
    let response = http.get(host + '/');
    check(response, {
        'index': success
    });
}

function setCurrency() {
    const currency = random(currencies);
    const data = {
        currency_code: currency
    };
    const response = http.post(host + '/setCurrency', data, headers);

    check(response, {
        'setCurrency': success
    });
}

function browseProduct() {
    const product = random(products);
    let response = http.get(host + '/product/' + product);

    check(response, {
        'browseProduct': success
    });
}

function addToCart() {
    // browseProduct
    const product = random(products);
    let responseBrowse = http.get(host + '/product/' + product);

    check(responseBrowse, {
        'browseProduct': success
    });

    // addToCart
    const quantity = random(quantities);
    const data = {
        'product_id': product,
        'quantity': quantity
    };
    const responseAdd = http.post(host + '/cart', data, headers);

    check(responseAdd, {
        'addToCart': success
    });
}

function viewCart() {
    let response = http.get(host + '/cart');
    check(response, {
        'viewCart': success
    });
}

function checkout() {
    addToCart();
    const data = {
        'email': 'someone@example.com',
        'street_address': '1600 Amphitheatre Parkway',
        'zip_code': '94043',
        'city': 'Mountain View',
        'state': 'CA',
        'country': 'United States',
        'credit_card_number': '4432-8015-6152-0454',
        'credit_card_expiration_month': '1',
        'credit_card_expiration_year': '2039',
        'credit_card_cvv': '672'
    };

    const response = http.post(host + '/cart/checkout', data, headers);

    check(response, {
        'checkout': success
    });
}
