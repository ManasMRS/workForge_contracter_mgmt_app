const Site = require('../models/Site.js');

const createSite = async (req, res) => {
    try {
        const site = new Site({
            ...req.body,
            userId: req.user.id
        });
        const response = await site.save();

        console.log('Site created');
        res.status(201).json(response);
    } catch (err) {
        console.log(err);
        res.status(500).json({ error: 'Internal Server Error' });
    }
};

const getAllSites = async (req, res) => {
    try {
        const sites = await Site.find({ userId: req.user.id });

        console.log('Sites fetched');
        res.status(200).json(sites);
    } catch (err) {
        console.log(err);
        res.status(500).json({ error: 'Internal Server Error' });
    }
};

const getSiteById = async (req, res) => {
    try {
        const site = await Site.findOne({ _id: req.params.id, userId: req.user.id });

        if (!site) {
            return res.status(404).json({ error: 'Site not found' });
        }

        res.status(200).json(site);
    } catch (err) {
        console.log(err);
        res.status(500).json({ error: 'Internal Server Error' });
    }
};

const updateSite = async (req, res) => {
    try {
        const updatedSite = await Site.findOneAndUpdate(
            { _id: req.params.id, userId: req.user.id },
            req.body,
            { new: true, runValidators: true }
        );

        if (!updatedSite) {
            return res.status(404).json({ error: 'Site not found' });
        }

        console.log('Site updated');
        res.status(200).json(updatedSite);
    } catch (err) {
        console.log(err);
        res.status(500).json({ error: 'Internal Server Error' });
    }
};

const deleteSite = async (req, res) => {
    try {
        const deletedSite = await Site.findOneAndDelete({
            _id: req.params.id,
            userId: req.user.id
        });

        if (!deletedSite) {
            return res.status(404).json({ error: 'Site not found' });
        }

        console.log('Site deleted');
        res.status(200).json({ message: 'Site deleted successfully' });
    } catch (err) {
        console.log(err);
        res.status(500).json({ error: 'Internal Server Error' });
    }
};

module.exports = {
    createSite,
    getAllSites,
    getSiteById,
    updateSite,
    deleteSite
};